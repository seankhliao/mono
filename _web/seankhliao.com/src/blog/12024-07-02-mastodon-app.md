# mastodon app

## why is it so hard to read reply chains

### _app_ for mastodon

So I have a mastodon account: [@seankhliao@hachyderm.io](https://hachyderm.io/@seankhliao)
(I don't use it too much).
A while ago I finally got onto Bluesky as well: as [@seankhliao.com](https://bsky.app/profile/seankhliao.com).
The first thing I immediately noticed about the Bluesky app was:
it was more of a Twitter clone than mastodon ever was.

The second thing I noticed was the lines and indenting of reply chains.
Following allow which tweet was a reply to what was always kind of hard with Twitter,
but somewhat doable as you sort of pivoted along each tweet.
Up to now, 
I had been using the official Mastodon app,
but I knew from the start that its display of nested replies was confusing.
Finally, I have some time to look at the competition,
I'll be looking at Android apps, the ones I found were:

- [Fedilab](https://play.google.com/store/apps/details?id=app.fedilab.android)
  - Thin rainbow lines to indicate reply nesting, posts are still all aligned
  - Doesn't handle deep nesting well, limited to 5 levels?
  - Doesn't pivot to a new root on selection (always shows parent context)
- [Megalodon](https://play.google.com/store/apps/details?id=org.joinmastodon.android.sk)
  - A flat list of replies
- [Mastodon](https://play.google.com/store/apps/details?id=org.joinmastodon.android)
  - The official app
  - Displays replies the same as the web interface, a flat list of replies
- [Moshidon](https://play.google.com/store/apps/details?id=org.joinmastodon.android.moshinda)
  - It kind of looks pretty, but still a flat list of replies
- [Openvibe](https://play.google.com/store/apps/details?id=com.plebstr.client)
  - An app that works with both mastodon and nostr
  - A flat list of replies
- [Pachli](https://play.google.com/store/apps/details?id=app.pachli)
  - A flat list of replies
- [Trunks](https://play.google.com/store/apps/details?id=com.decad3nce.trunks)
  - Pretty, looks like a fully custom display rather than a reskinned web browser?
  - More oriented towards social discovery...
  - Displays as thick lines on the side, indenting replies
  - Can pivot root
- [Tusky](https://play.google.com/store/apps/details?id=com.keylesspalace.tusky)
  - Looks mostly like the web interface, also a flat list of replies

From the looks of it,
only Fedilab and Trunks show threaded replies well,
and of the two,
I prefer Trunks since it handles deeper nesting better.
The tradeoff is that a long self chain looks weird as it indents a level every time,
but I think it's ok for now.
