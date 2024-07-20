# GCP Uptime Checks, Service Agent authentication

## secretless auth for things

### _GCP_ Uptime Checks, secretless auth

[GCP Uptime Checks](https://cloud.google.com/monitoring/uptime-checks)
is one way to probe your endpoints on an interval from global locations,
to check that a URL is up and responding correctly.

With public checks, 
the URL has to be available on the internet,
but what if you want some sort of authentication?
GCP Uptime Checks supports HTTP Basic Authentication,
custom HTTP Headers, and Service Agent Authentication.
This last option is particularly interesting
because it presents a way to not have any secrets configured.

#### _Service_ Agent Authentication

What happens when you configure this?
GCP will give you a service account identity (email)
that will make the request,
e.x.: `service-330311169810@gcp-sa-monitoring-notification.iam.gserviceaccount.com`.

The request you get looks something like the following:

```http
GET /gcp-uptime HTTP/1.1
Host: reqlog.liao.dev
Accept: */*
Accept-Encoding: deflate, gzip
Authorization: Bearer eyJhbGciOiJSUzI1NiIsImtpZCI6ImYyZTExOTg2MjgyZGU5M2YyN2IyNjRmZDJhNGRlMTkyOTkzZGNiOGMiLCJ0eXAiOiJKV1QifQ.eyJhdWQiOiJodHRwczovL3JlcWxvZy5saWFvLmRldiIsImF6cCI6IjEwNjc2Mjk1MDk4NzAwODAwODIzMyIsImVtYWlsIjoic2VydmljZS0zMzAzMTExNjk4MTBAZ2NwLXNhLW1vbml0b3Jpbmctbm90aWZpY2F0aW9uLmlhbS5nc2VydmljZWFjY291bnQuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImV4cCI6MTcyMTQ4OTYxOSwiaWF0IjoxNzIxNDg2MDE5LCJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJzdWIiOiIxMDY3NjI5NTA5ODcwMDgwMDgyMzMifQ.rfRUN4IYCL130wppUp7wLWAMteA_GfGJopGfP75mSUlXlChOCTxSpeWbUUYS43_J4Q46dpDvnTBwSdOGNpA8ctxrGPIuoZ7dj7lzArEX2e5EyDWhGSNzvQgZj2VLOGA05RuJvC2OrqsUD-GpGFJBMsHqECW7Uqn2ny3819Wl88_YZdhYRTcM75QKs_FizFKC_QRCTi4cix_W-as9pcyUih4JzAUTjRR-tZuFCkBIaCWOXahejQLZ-KL8eNAfB0-wIbe20d7i5n5BiUWkR6ZjXOe6sLdy9IU_sk_ZOKaRKKv9cx77VvYAhKQTgk1IK6g8UO-QglBPS8j5rmxWBRnqXw
Check-Id: validate-check-id
Traceparent: 00-3190f4f73704efb77d7053927ff9cc44-be6c80f74ecaa37f-01
Tracestate: 
User-Agent: GoogleStackdriverMonitoring-UptimeChecks(https://cloud.google.com/monitoring)
X-Envoy-External-Address: 35.233.167.246
X-Forwarded-For: 35.233.167.246
X-Forwarded-Proto: https
X-Request-Id: c53bb128-efc6-9433-b931-937c646e42f3
```

The bearer token is a jwt that can be decoded and validated:

```json
{
  "alg": "RS256",
  "kid": "f2e11986282de93f27b264fd2a4de192993dcb8c",
  "typ": "JWT"
}
{
  "aud": "https://reqlog.liao.dev",
  "azp": "106762950987008008233",
  "email": "service-330311169810@gcp-sa-monitoring-notification.iam.gserviceaccount.com",
  "email_verified": true,
  "exp": 1721489619,
  "iat": 1721486019,
  "iss": "https://accounts.google.com",
  "sub": "106762950987008008233"
}
```

As an example,
with [Envoy Gateway](https://gateway.envoyproxy.io/),
the `SecurityPolicy` would look like:

```yaml
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: SecurityPolicy
metadata:
  name: jwt
  namespace: reqlog
spec:
  targetRef:
    group: gateway.networking.k8s.io
    kind: HTTPRoute
    name: reqlog
  jwt:
    providers:
    - name: google
      issuer: "https://accounts.google.com"
      audiences:
        - "https://reqlog.liao.dev"
      remoteJWKS:
        uri: "https://www.googleapis.com/oauth2/v3/certs"
```
