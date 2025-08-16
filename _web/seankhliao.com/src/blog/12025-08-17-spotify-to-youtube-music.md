# Spotify to Youtube Music

## making the jump

### _spotify_ to youtube music

Recently, I had a billing issue with Spotify,
which made me think it wasn't really worth it anymore to pay for premium.
My account is in TW, where pricing is NTD150 / month,
and I was forced to switch to the UK, which is GBP12.00 / month,
an almost 3x increase in price.
So I stopped.

I'd already been paying for Youtube Premium,
because I find ad-free + offline on mobile to be worth it,
and that comes with Youtube Music,
so I'm using that instead.

#### _experience_

The following are I think the key UX points.

##### _playlists_

I don't maintain many playlists myself:
my spotify playlists consisted of:

- my saved tracks which i reset every year
- a snapshot of the years saved tracks
- the yearly spotify wrapped playlist

Still I wanted to keep them.
Looking around online,
it looked like the options were either janky python scripts that didn't work
or paid online services.

In reality, all you needed was to open the YT music app,
and it would recommend a service to migrate your playlists for free,
powered by Tune My Music.
If you hid the card recommending it,
it's in Settings -> Privacy & Data -> Transfer my playlists from another service.

It was pretty quick and accurate as well.
I still don't keep many personal playlists.

##### _music_ recommendations

Rather than maintain my own playlists,
I lean heavily on recommended / generated playlists.
After using YT Music for a bit,
I finally understood people's complaints about Spotify being too repetitive.
It really does seem to not expand much beyond the artists you follow.

In contrast, within the first few days of using YT Music,
there were quite a few instances where I recognized the voice,
singing a song I hadn't heard before.
Turns out there are a bunch of collabs that aren't directly under the artist's name
and Spotify never surfaced them to me.

YT Music also has what I feel are a better implementation of radios:
select your starting set of artists or songs and go from there,
rather than only starting from one in spotify.
The automatic ones are more varied as well,
and it has a really fun ai prompted playlist / radio generator,
where you can just give it vibes...

The wider range of music discovery does mean that
YT Music tends to drift off topic over time though,
such as when you leave it playing over a day or overnight,
the genre shifts.

##### _catalogue_

I think YT music has a much bigger catalog than Spotify,
since it can also draw from all the things that are just on Youtube,
rather than having to be published speicifcally to a music platform.
It also means more covers,
and more of the less marketed songs

##### _history_

With spotify,
the only way to find out what you'd been listening to recently in the past was through their API
(returning the last 50 songs),
or with a third party service like last.fm.

With YT Music,
in app there's your last 2 days listening history,
but third party integrations barely exist.
For last.fm, you have to install software that watches local device playback and submit that.
I went with
[Pano Scrobbler](https://play.google.com/store/apps/details?id=com.arn.scrobble&hl=en_GB)
though I didn't really try much else.
At the same time, I also started an account with
[ListenBrainz](https://listenbrainz.org/) as a backup
(apparently made by last.fm founder + MusicBrainz founder after last.fm was sold).

##### _live_ event recomemndations

Related to listening history, is concert recommendations.
I sed Songkick before, but it can only sync from Spotify.
Online people claim it could sync with last.fm, but I never found the option to.

The other main choice is BandsInTown.
That can sync with YT Music (and a few other services),
it also syncs from Last.fm.
I think this may be more useful going forward.

##### _offline_

In spotify, downloading a playlist also saves it to your library,
in the Youtube Music app, they're different actions.
It takes some getting used to,
but as I'm light on my own playlists,
I just stick to viewing downloads by default.

Spotify has an offline backup generated playlist,
while YT music has both its offline mixtape,
but also a selection of other playlists it thinks you might be interested in.

For live playback, it seems Spotify caches ahead further (a few more songs)
compared to YT music, so if I'm streaming a radio of songs I haven't downloaded,
Spotify will play uninterrupted for my commute,
which YT Music will pause pretty quickly.

YT Music also has the annoying limitation of being unable to like songs offline,
though you might be able to manually add them to playlists.

##### _multi_ devices

Both services only allow you to play on one device at a time,
but Spotify has a more integrated experience where every device will show your playback progress,
and you can switch playback devices in app.
YT music you can't see what the other device is playing,
and it stopping simultaneous playback isn't instant,
I only know about the limitation because I see an error message on the other device after a while...

##### _audio_ quality

TBH I can't really tell of any difference.
