# blog website design

## why my website is the way it is

### _blog_ website design

Sometimes people tell me that my website (this one) look pretty.
Thank you.

The rest of this post will go over why it's designed this way.

#### _content_ and style

I think I went through a few dozen styles of personal websites.
My earlier ones were photography centric,
and I remember trying to do masonary layouts with flexbox and such
before CSS grid had native masonary (it was kind of hard).
Later I decided I didn't want to put the photos I took on the internet.

After that,
I didn't have much to put on my website,
so I went through hundreds of personal portfolio sites
linked from places like [awwwards.com](https://www.awwwards.com/),
Dibbble, Behance, other aggregators, and random google searches.
A lot of these were design heavy,
and for a while I also did a lot in svg animations and such.
It was pretty, but it didn't have a lot of content.

2019 seems to be when I decided to land on my current blog.
At first I wanted to do something like
[Chris Siebmann's Wandering Thoughts](https://utcc.utoronto.ca/~cks/space/blog/__IndexChron)
with a post per day,
but I'm not that productive...
so the frequency tapered off,
but this is still mostly a blog on technical content.

As for style, the big splash header was something I liked from all the design sites I found,
but I didn't want to draw a picture, so I just used my name.
Slightly vain, but it's my site about me.
I took out a notebook (paper) and drew a lot of variations until I had one I liked.
Besides the splash,
I also wanted some elements like pictures and code to be full bleed,
but the text would otherwise be width limited to aid reading
(somewhere between 40-120 chars seems to be the consensus).

Colour wise, I know I wanted to be minimal:
black, white, `gray`,
with just a splash of **purple** for highlights.

#### _technical_ constraints

I know I wanted a static site,
I'd use firebase hosting, but maybe I could switch to something else like github pages if necessary.
I also don't like frontend dev, so definitely no react or vue or whatever framework of the month.
Also, JS only for progressive enhancement.
I think I do a copy button and table sorting,
plus analytics.

I wanted to write content in markdown,
so the output was relatively simple html with not a lot of classes and such
(later I'd add syntax highlughting for code).

All that means I have a chunk of rendered html I can insert into a templated envelope,
and css grid seemed like the most reasonable way to organize it all
considering I wanted elements of varying width.

Did I miss anything?
