# commercial vpn

## I'm there

### _commercial_ vpn

In the UK, a terrible law has come in to effect:
the Online Safety Act.
This has pushed me to finally get one of those VPNs that change your exit location
to look like it's from a different country...

Before this, I had the Google Pixel VPN that came with my Pixel 8 Pro,
but I never thought it was all that useful.
Anything important goes over HTTPS,
it still puts your exit in the same country,
and it was slow to get connected,
which was especially troublesome for places with intermittent internet,
like the London Tube.

I also had Tailscale,
but they're a more traditional VPN
in that they form a private overlay network between your own devices.
In the past I sometimes ran servers that could act as exit nodes,
but not right now.
Also, running many exit nodes isn't exactly cheap.

Don't believe all those "privacy" claims the shady VPN companies try to sell you on.
Modern web tracking is way more effective than just your source IP,
(and destination for intermediaries) which is more or less the only thing the VPNs can hide.

I think my choice was pretty easy:
on mobile devices, you can only have 1 VPN active at a time,
so the [Mullvad add on for Tailscale](https://tailscale.com/mullvad) was the best choice for me.
I could keep access to my own devices when necessary,
and I think Mullvad's commitments such as
[RAM only infrastructure](https://mullvad.net/en/blog/we-have-successfully-completed-our-migration-to-ram-only-vpn-infrastructure)
make them a more trustworthy company to do business with.
