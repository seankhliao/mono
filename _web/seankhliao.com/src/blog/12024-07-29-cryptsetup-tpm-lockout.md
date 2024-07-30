# cryptsetup tpm lockout

## things you forget

### _cryptsetup_ lockout

My laptop is still running the same 
[Arch Linux install](/blog/12024-01-02-archlinux-reinstall/)
from January this year,
including full disk encryption with TPM2 and fido2 keys.
With multiple unlock options,
it usually defaults to just the TPM with a PIN,
so that's what I enter every time I boot the machine.

Last night,
I was updating my machine,
and also decided I'd check for firmware updates:

```sh
fwupdmgr refresh
fwupdmgr update
```

It said it needed a reboot, so I let it do that.
Upon rebooting,
I entered the TPM2 PIN as usual,
but was then prompted for the disk password...
Which was when I realized I don't remember what the password was.

15 minutes of trying passwords later,
I had almost given up hope,
and dug out the live usb I still had.
I was going to try unlocking the partition:

```sh
cryptsetup open /dev/nvme0n1p2 root
```

This time,
I was prompted for verification from my fido2 key,
and I saw a way forward.
I could wipe the slot with the passphrase I forgot
and add a new passphrase by authenticating with a token.

```sh
cryptsetup luksKillSlot /dev/nvme0n1p2 0 --token-only
cryptsetup luksAddKey /dev/nvme0n1p2 --key-slot 0 --token-only
```

This allowed me reboot into my normal environment.
As I was reviewing the config for TPMs using `systemd-cryptsetup`,
it finally clicked what happened:
the TPM key for unlocking the disk was bound to PCR7,
which includes the EFI firmware in its measurement,
firmware which I had updated.
So by updating the firmware,
the PCR value changed, invalidating the key,
requiring a separate unlock method to proceed
(which I had conveniently forgotten).

To recover,
I wiped the slot with the TPM, and reenrolled it:

```sh
systemd-cryptenroll --wipe-slot 1 /dev/nvme0n1p2
systemd-cryptenroll --tpm2-device auto --tpm2-with-pin true
```

What I wasn't sure of was why it wouldn't prompt for fido2 tokens on boot.
