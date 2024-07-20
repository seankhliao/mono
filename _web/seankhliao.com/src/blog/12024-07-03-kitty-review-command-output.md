# (re)viewing the last command's output

## when your terminal is so full of stuff

### _re_ viewing command output

Working with Kubernetes,
I'm often faced with output that is hundres or thousands of lines long,
whether it's all Deployment manifests for a cluster,
logs for a pod,
or something else that just scrolls by me.
If I had foresight that I'd need to wade through endless lines of output,
I'd usually tack a ` | nvim -` to the end of the command,
piping the output into my editor ([neovim](https://neovim.io/)) which I can then manipulate.

Sometimes though, I forget,
or I've closed the window
and the state of the system has changed so I can't just rerun the previous command again.
A while back,
I saw one of the shiny new terminals with deep shell integration
where each line of the command prompt got its own dedicated block.
I didn't want to switch terminal,
but I did want that feature.

A little more research,
and I realized I could have something close to that:
[kitty](https://sw.kovidgoyal.net/kitty/)
has two (actually more, but two I care about) [mappable actions](https://sw.kovidgoyal.net/kitty/actions/):
`show_scrollback` and `show_last_command_output`.
These feed the output of the terminal scrollback into a pager,
and I could set my pager to be neovim.

The only problem was... all the escape codes that remained,
plus the lines wrapped on the display breaks rather than original line endings for some reason.
I could remove the majority of escape codes with
the following sed script,
but that still left some, plut the hard line wraps.

```
scrollback_pager bash -c 'sed $"s,\x1B\[[0-9;]*[a-zA-Z],,g" | nvim -R'
```

Some more poking around,
and I finally found [mikesmithgh/kitty-scrollback.nvim](https://github.com/mikesmithgh/kitty-scrollback.nvim),
a kitty kitten plus neovim plugin pair that would strip the escape codes,
colorize the output,
and keep the right line wraps.
The following is my config to use it with [pckr.nvim](https://github.com/lewis6991/pckr.nvim),
note the `restore_options` setting to un-override some settings line line numbers and soft line wraps.

```lua
require("pckr").add({
    {
        "mikesmithgh/kitty-scrollback.nvim",
        config = function()
            require("kitty-scrollback").setup({
                {
                    restore_options = true,
                },
            })
        end,
    },
})
```

The controls do require some getting used to though,
the default view you're in has most of the editing options dissabled,
and you get a floating window on yank to actually edit.
So it's more focused on preparing the next command,
rather than extracting data, but I suppose it's good enough as a backup.
