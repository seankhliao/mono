# eduroam iwd

## eduroam, iwd version

My [previous attempts](/blog/12019-09-04-eduroam/)
to get eduroam wifi with [wpa_supplicant](https://wiki.archlinux.org/index.php/WPA_supplicant)
more or less worked.
But some recent updates seem to have made everything unstable again.
So why not try [iwd](https://wiki.archlinux.org/index.php/Iwd)

#### Correction 2019-09-16

It doesn't work at another location
back to `wpa_supplicant`

#### _UvA_ (University of Amsterdam)

The only account I have access to right now,
they supposedly use `TTLS` with `MSCHAPV2` for phase2,
**which works as described for `wpa_supplicant`**,
but `iwd` is weird and the error messages are beyond useless even with debugging turned on.
Following the advice of some archlinux forum post to "play around with the eap method",
`PEAP` works :facepalm:

```
[Security]
EAP-Method=PEAP
EAP-Identity=anonymous@uva.nl
EAP-PEAP-Phase2-Method=MSCHAPV2
EAP-PEAP-Phase2-Identity=...@uva.nl
EAP-PEAP-Phase2-Password=...

[Settings]
Autoconnect=true
```

#### Update 2024-07-18: NetworkManager

While I've always used iwd directly through files or `iwctl`,
iwd can also be a backend for NetworkManager.

UvA provides a config tool available for download at 
[wifiportal.uva.nl](http://wifiportal.uva.nl/),
which generates a connection profile at:
`/etc/NetworkManager/system-connections/eduroam.nmconnection`.
NetworkManager will read the file and generate a corresponding 
iwd config at `/var/lib/iwd/eduroam.8021x`.

I've been told the the UvA tool includes the following lines in
`eduroam.nmconnection` which should be removed / commented out:

```
ca-cert=/home/user/.joinnow/eduroam.crt
domain-suffix-match=radius.uva.nl
```

if left in place,
they get translated into the following iwd config:

```
EAP-PEAP-CACert=/home/user/.joinnow/eduroam.crt
EAP-PEAP-ServerDomainMask=*.radius.uva.nl
```

which apparently iwd doesn't need or like 
(or is unnecessary for UvA's current network configuration).

Thanks to Jason for the sharing their working configuration.
