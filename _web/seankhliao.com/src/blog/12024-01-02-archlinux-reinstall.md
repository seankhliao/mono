# Arch Linux Reinstall

## Secure Boot and Full Disk Encryption

### _Arch_ Linux (re)install

One thing that always bothered me was that I had never bothered to setup full disk encryption
the last time I reinstalled [Arch](https://archlinux.org/) on my laptop.
I was looking for something simple and just did plain ext4.

#### _security_

This time I'm following 
[LUKS on a partition with TPM2 and Secure Boot](https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system#LUKS_on_a_partition_with_TPM2_and_Secure_Boot).

Full disk encryption primarily protects the data on disk when the computer is off.
Binding the encryption to the TPM and secure boot should mean that you can't take the drive out
and attack it in a different system?
I'm keeping both password and fido2 keys though,
so what it practically gets me is a shorter pin on boot vs a full length password to type.

#### _process_

We start with an Arch iso, from [Downloads](https://archlinux.org/download/).
Verifying it with:

```sh
pacman-key -v archlinux.iso.sig
```

Writing it to a usb with:

```sh
dd bs=4M if=path/to/archlinux.iso of=/dev/sda conv=fsync oflag=direct status=progress
```

Next we reboot,
going into bios to reset the secure boot settings (putting it in setup mode).

We start with clearing the disk (grab a backup first for package lists, `/etc`, `/home/$user`, `/var/lib/iwd`).
My disk didn't support `--secure`, so `--zeroout` will have to do:

```sh
blkdiscard --force --zeroout /dev/nvme0n1
```

Set the time

```sh
timedatectl set-timezone Europe/London
```

and make sure internet works (ip reachable, dns resolvable)

```sh
ping 8.8.8.8
ping dns.google
```

Next, disk partitioning with GPT and 1 efi partition and 1 main partition:

```sh
gdisk /dev/nvme0n1
n .. EF00 # efi partition, 1G
n ... 8304 # linux main partition, remainder
```

Create the efi filesystem,
and the main partition on luks:
```sh
mkfs.fat -F 32 /dev/nvme0n1p1

cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 root
mkfs.ext4 -i 1024 /dev/mapper/root
mount /dev/mapper/root /mnt
mount --mkdir /dev/nvme0n1p1 /mnt/efi
```

Update the mirrorlist for fast mirrors,
I took the list from my previous install.
Then it's time to install the base system,
organized roughly as: system core, system management, desktop, dev:

```sh
pacstrap -K /mnt base linux linux-firmware intel-ucode \
  efibootmgr exfat-utils htop iftop iotop man-db man-pages powertop sbctl terminus-font \
  bluez bluez-utils brightnessctl fprintd grim i3status kitty mako noto-fonts noto-fonts-cjk noto-fonts-emoji pam-u2f \
  pipewire pipewire-pulse playerctl pulsemixer slurp sway swaybg swayidle wf-recorder wl-clipboard wofi xdg-desktop-portal-wlr \
  age aria2 base-devel eza fzf git git-delta go go-yq jq mkcert neovim openssh ripgrep rsync tailscale unrar unzip vim xsv zsh zsh-completions
```

Next we setup the newly created disk:

```sh
arch-chroot /mnt

hwclock --systohc
ln -s /usr/share/zoneinfo/Europe/London /etc/localtime

nvim /etc/locale.gen
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

echo hwaryun > /etc/hostname
vim /etc/hosts # 127.0.0.1 localhost
# copy /etc/systemd/network/* for device / DHCP

ln -s /usr/lib/systemd/resolv.conf /etc/resolv.conf
systemctl enable systemd-networkd systemd-resolved systemd-timesyncd iwd pcscd.socket bluetooth tailscale

chsh
passwd 
# change default shell
vim /etc/default/useradd 

# netdev for iwd
groupadd adm docker netdev sudo
# create user, add to above groups
echo '%sudo ALL=(ALL:ALL) ALL' > /etc/sudoers.d/sudo

echo 'quiet bgrt_disable rd.luks.options=password-echo=no,tpm2-device=auto,fido2-device=auto' > /etc/kernel/cmdline

vim /etc/mkinitcpio.conf # change hooks
vim /etc/mkinitcpio.d/linux.preset # uncoment _uki settings

# clear efi variables if any still remain 
efibootmgr -B -b 0000

# bootloader
bootctl install

sbctl create-keys
sbctl enroll-keys -m

# create uki 
mkinitcpio -P

sbctl verify

reboot
```

Turn on secure boot in the bios
Now we can use the tpm:

```sh
systemd-cryptenroll --password /dev/nvme0n1p2
systemd-cryptenroll --fido2-device auto /dev/nvme0n1p2
systemd-cryptenroll --tpm2-device auto --tpm2-with-pin true /dev/nvme0n1p2
```

Finally we can work with our new user:

- enroll fingerprints with `fprintd-encroll -f left-index-finger user`
- edit `/etc/pam.d/system-local-login` and `/etc/pam.d/system-auth` with `auth sufficient pam_fprintd.so max-tries=2 timeout=15`
- enroll fido2 keys with `sudo pamu2fcfg -u user -o pam://hwaryun -i pam://hwaryun | sudo tee -a /etc/u2f_keys`
  - and `pamu2fcfg -n -o pam://hwaryun -i pam://hwaryun | sudo tee -a /etc/u2f_keys`
  - and edit the pam files with `auth sufficient pam_u2f.so cue origin=pam://hwaryun appid=pam://hwaryun authfile=/etc/u2f_keys [cue_prompt=touche]`

Install [paru](https://github.com/Morganamilo/paru) (use a prebuilt bin, reinstall itself)
And finally desktop setiup (clone dotssh, dotconfig), download and install tools and repos.
