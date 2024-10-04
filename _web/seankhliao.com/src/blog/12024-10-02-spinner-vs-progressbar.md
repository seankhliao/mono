# spinner vs progress bar

## how much work is there to do?

### _spinner_ vs progress bars

A few weeks ago,
I was sufficiently annoyed by my own tools spewing out screenfuls of log lines reporting progress,
that I thought to implement some sort of minimal ui like a progress bar.
I had always quite liked the progress bars used by [pacman](https://wiki.archlinux.org/title/Pacman),
the package manager used primarily by Arch Linux,
but I soon ran into 2 big issues.

First, all the progress bar options in Go were terrible.
Too over featured, difficult to control,
and they can't display text and bars properly at the same time.
Second, figuring out how much work you have to do can apparently be qquite hard.
What counts as 1%? 
What is 100% set to when you have an infinite stream to process?
Plus, the intermingling of real work and display management was ugly
and I started to understand the desire for MVC or something similar.

I gave up and switched to using a spinner.
Plus some text with `X / Y` when I knew about it,
and just a status message otherwise.
