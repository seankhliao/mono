# macos path_helper

## why isn't my computer mine

### path_helper on macos zsh

ZSH [loads a few files](https://zsh.sourceforge.io/Doc/Release/Files.html)
on startup.

You might think that the `~/.zshenv` file is a good place to put some environment variables.

But macOS says no!
For some mind boggling reason,
they have a `path_helper` which decides to reorder the paths in your `PATH` env.

So... the way around it is to make your modification later.
In `~/.zshrc`.

Here's a [gist describing the same problem](https://gist.github.com/liviaerxin/c1e80a42d78091f789b4ebdbf84868f7).
