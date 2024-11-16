# jj revset diagram

## understanding revsets

### _jj_ revsets diagram

I've been experimenting with [martinvonz/jj](https://github.com/martinvonz/jj) (aka Jujutsu),
a newish version control system with some git compatibility.

One of the fun things is jj's language of [revsets](https://github.com/martinvonz/jj/blob/main/docs/revsets.md)
where there are shorthands for specifying ranges of commits.
Well the descriptions were confusing,
and light experimentation on my more or less linear history repos weren't too enlightening,
so I went to the effort of creating a diagram using a more convoluted commit graph

![jj revsets](/static/jj-revsets.svg)
