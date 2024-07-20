# GCP Workload Identity Federation

## no more service accounts

### _Workload_ Identity Federation

Last year when I setup my local (off cloud) Kubernetes cluster,
I found that you could use workload identity to trust the kubernetes identities
and impersonate GCP service accounts.
Ref: [blog post](/blog/12023-12-24-local-kubernetes-gcp-workload-identity/)

This year, I see they've upgraded it to not require impersonation at all,
allowing you to use the workload identity directly.
The upstream docs are still the same at
[Configure Workload Identity Federation with Kubernetes](https://cloud.google.com/iam/docs/workload-identity-federation-with-kubernetes).

Compared to the previous config,
this time we have two new keys: `universe_domain` and `token_info_url`,
and no longer need `service_account_impersonation_url`

```json
{
		"universe_domain":    "googleapis.com",
		"type":               "external_account",
		"audience":           "//iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID",
		"subject_token_type": "urn:ietf:params:oauth:token-type:jwt",
		"token_url":          "https://sts.googleapis.com/v1/token",
		"credential_source": {
			"file": "/var/run/service-account/token",
			"format": {
				"type": "text"
			}
		},
		"token_info_url": "https://sts.googleapis.com/v1/introspect"
}
```

Mounting the config and pointing GCP SDKs to it is still the same,
though I'm still confused by the `audience` not needing `https:` in the config
but needing it in the GCP and token setup.

Also, I realized that if you used a projected serviceAccountToken volume,
the default token isn't mounted,
causing issues if the application talked to the Kubernetes API.
Setting `automountServiceAccountToken` appears to be the easiest way to get it back.

```yaml
spec:
  template:
    spec:
      automountServiceAccountToken: true
      containers:
        - env:
            - name: GOOGLE_APPLICATION_CREDENTIALS
              value: /etc/workload-identity/creds.json
          volumeMounts:
            - name: token
              mountPath: /var/run/service-account
              readOnly: true
            - name: gcp-creds
              mountPath: /etc/workload-identity
              readOnly: true
      volumes:
        - name: token
          projected:
            sources:
              - serviceAccountToken:
                  audience: https://iam.googleapis.com/projects/330311169810/locations/global/workloadIdentityPools/kubernetes/providers/justia-asami
                  expirationSeconds: 3600
                  path: token
        - name: gcp-creds
          configMap:
            name: gcp
```

With this we can grant access to the new [principal types](https://cloud.google.com/iam/docs/workload-identity-federation)
such as:

```
# a specific service account
principal://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/subject/system:serviceaccount:KSA_NAMESPACE:KSA_NAME

# service account with the same name in all namespaces
principalSet://iam.googleapis.com/projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/attribute.service_account_name/KSA_NAME
```
