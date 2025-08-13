# Updating luks keys

## tpm reset

### Updating luks keys

If you encrypt your disk with full disk encryption (luks)
and usually unlock it with a TPM,
you might find that a firmware update invalidates the PCR signatures
forcing you to unlock with a password.

Once you're back in the system,
it's time to re-enroll the tpm key with updated measurements:

First inspect your device,
look for the token and the corresponding key slot.

```sh
$ sudo cryptsetup luksDump /dev/nvme0n1p2

Keyslots:
  0: luks2
    ...

Tokens:
  0: systemd-tpm2
    ...
	Keyslot:    1
```

Clear the token and key slot:

```sh
sudo cryptsetup --token-id 0 token remove /dev/nvme0n1p2
sudo cryptsetup luksKillSlot /dev/nvme0n1p2 1
```

And enroll the tpm again.

```sh
sudo systemd-cryptenroll --tpm2-device auto --tpm2-with-pin true /dev/nvme0n1p2
```

Aside: if you're wondering which passphrase corresponds to which slot,
you can test opening the device:

```sh
sudo cryptsetup luksOpen --test-passphrase --verbose /dev/nvme0n1p2
```
