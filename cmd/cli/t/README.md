# t

`t` wrap [ripgrep](https://github.com/BurntSushi/ripgrep)
to generate aliases to open [neovim](https://github.com/neovim/neovim)
at the line:column of search results.

By default, lines longer than 4096 chars are excluded, set `T_LONG=1` in the environment to include.

## install

```sh
$ go install go.seankhliao.com/mono/cmd/t@latest
```

And add the following into shell config:

```sh
function t() {
    command t -i "$@"
    source /tmp/t_aliases 2>/dev/null
}
```

## example output

```
» t con
input.txt
[1] 6:5:Nam consequat orci leo, eget lobortis ex semper vel
[2] 9:20:Quisque vestibulum condimentum tincidunt

two.txt
[3] 1:48:Nullam auctor felis nulla, non suscipit tortor convallis vel
[4] 2:14:Maecenas vel convallis ante
[5] 7:51:Proin venenatis tellus pretium arcu pellentesque, congue mattis risus posuere

example.txt
[6] 1:29:Lorem ipsum dolor sit amet, consectetur adipiscing elit
[7] 3:20:Ut a diam at metus condimentum fermentum et quis est
[8] 10:19:Integer hendrerit consectetur aliquet
[9] 11:9:Vivamus consequat convallis dolor, eu lobortis ligula condimentum ut
[10] 12:30:Praesent quis ante bibendum, congue nunc vel, facilisis dui
[11] 13:35:Morbi interdum efficitur erat sed consectetur.

four.txt
[12] 3:33:Morbi maximus facilisis ipsum a condimentum
[13] 13:8:Aenean convallis faucibus consequat.

final.txt
[14] 8:29:Lorem ipsum dolor sit amet, consectetur adipiscing elit
[15] 9:39:Suspendisse semper felis id malesuada convallis
```

Open the first result with `e1`.
