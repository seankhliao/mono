# adding CA roots

## all the custom bundles

### _Custom_ Certificate Authority Roots

Recently Mozilla published an update (v3.0) to their
[Root Store Policy](https://www.mozilla.org/en-US/about/governance/policies/security-group/certs/policy/).
As one of the most widely used root stores via inclusion
in various linux distro ca-certicates packages,
what they say is quite important.

The highlights might be to reaffirm 
the [Certification Authority Browser Forum (CA/Browser Forum)](https://cabforum.org/)
TLS [Baseline Requirements (BR)](https://cabforum.org/working-groups/server/baseline-requirements/)
around [Delayed Revocation](https://www.mozilla.org/en-US/about/governance/policies/security-group/certs/policy/#613-delayed-revocation),
where repeated offences will not be tolerated.
Also, in the works are a [testing plan](https://groups.google.com/a/mozilla.org/g/dev-security-policy/c/xC8AQlMYg10)
to randomly revoke certificates
to check that process are in place to handle revocation and reissuance
on a timely schedule.

For companies,
this may present a risk in the operattions of internal services.
If it's not intended for wider web use,
it should probably use a private CA where you have full control over the certificate lifetimes.
How to setup and run a CA is out of scope,
but we'll look at how to trust the CA certs.

Internal services may be written in a wide variety of languages,
each with their own crypto libraries.

For most Linux distros, start with (crt == PEM format):

```bash
$ cp ca.crt /usr/local/share/ca-certificates/
$ update-ca-certificates
```

This also updates the bundle in `/etc/ssl/certs/ca-certificates.crt`.

Now we get to the various language runtimes:

Node.js bundles their own set of certs in the runtime.
To use your updated certs you can do one of:
* `NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt`: use the runtime bundled certs, plus the system bundled certs pointed to here.
* `--use-openssl-ca`: use openssl behaviour and read system certs, and look at `SSL_CERT_DIR` and `SSL_CERT_FILE`
* `--use-system-ca`: like the above, but cached on first load.

Python `requests` also bundles their own certs,
use `REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt` to point it to the system store.

Go uses the system stores by default,
but also respects `SSL_CERT_DIR` and `SSL_CERT_FILE`.

Java usually has its own keystore managed using `keytool` like:
`keytool -import -alias some-name -file ca.pem -keystore /path/to/keystore -storepass changeit --noprompt`.
where `/path/to/keystore` is `${JAVA_HOME}/lib/security/cacerts`.
But you can instead link that to the system store updated by `update-ca-certificates` 
at `/etc/ssl/certs/java/cacerts`.
