# practical tpm2

## forget attestation

### _tpm2_ usage

Trusted Platform Modules (TPMs) are dedicated microcontrollers
for performing cryptographic operations.
On the surface, it doesn't sound very interesting,
but a key property is that every TPM module has a unique random seed burned in,
allowing for platform bound operations,
or in other words operations only this specific device can do 
(and devices are bound to the hardware).

Typically, you might hear about TPMs in the context of (remote) attestation,
where sofware can prove the platform was started from a known state.
This works through the cooperation of the formware, BIOS, and OS,
to report data during the boot process as it's loaded/executed to the TPM,
which records `sha(old_state + sha(new_data))` into Platform Configuration Registers (PCRs).
The resulting values can be compared against expected PCR values to check if it's in a known state,
and it can be signed by the TPM with a burned in key (Enrollment Key, EK)
(indirectly via Attestation Keys AIKs) to verify it came from a specific platform.

Attestation might be interesting, 
but not very useful in most cases.
I want to look at how you might actually use it in an app.

#### _crash_ course

I'll be looking at TPM 2.0 
because that's what I have, and what's more widely supported in most places.
The specs are at
[TPM 2.0 library specification](https://trustedcomputinggroup.org/resource/tpm-library-specification/).

TPMs are mostly stateless,
they hold PCRs for recording platform state,
NVRAM for some other data,
a minimal amount of working memory,
and primary seed values.
From a primary seed, using a known template (config values),
you can deterministically derive a primary object,
or storage root key SRK.

With a SRK active,
you can generate more ephemeral objects (keys) using templates,
these will be returned as public key + private key encrypted by SRK.
To use it, load it into the TPM where it will be decoded,
and you can use it to perform cryptographic operations.
It's up to you to persist the outputs of the (non-primary) objects
if ou want to reuse them in the future.

RSA keys can do sign/verify encrypt/decrypt with a single keypair.
ECC keys can't, instead the only primitive is between 2 keypairs
where Pub-A with Priv-B can derive the same shared secret (Z point) as 
Priv-A with Pub-B.
In practical terms `TPM2_ECDH_KeyGen` 
will take a known public key and return a shared secret key to be used for encryption, 
and the public portion of an ephemeral which needs to be persisted.
To decrypt, take the public portion of the ephemeral key along with a TPM bound ECC key,
and re-derive the shared secret with `TPM2_ECDH_ZGen`.
