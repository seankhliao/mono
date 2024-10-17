# switching kubeconfig

## too many clusters

### switching kubeconfigs

When you work with too many kubernetes clusters,
you need a way to switch between connecting to each one.

`KUBECONFIG` is the environment variable that points to your config files,
separated by `:`,
and each config file can have multiple contexts (cluster, user, namespace combinations),
and one current context.

`kubectl` has a very basic interface:
`kubectl config get-contexts`, `kubectl config use-context`.
It's too much to type,
it's not easy to find a context to connect to,
and it's global to your user.

[`kubectx`](https://github.com/ahmetb/kubectx)
was the first main innovation in this space,
primarily through fuzzy searching with [`fzf`](https://github.com/junegunn/fzf).
But it was still global.

[`kubeswitch`](https://github.com/danielfoehrKn/kubeswitch)
came next,
allowing isolation between terminal sessions by creating temporary kubeconfig files,
and using shell functions that modify the current environment.

[`kubie`](https://github.com/sbstp/kubie)
sounds like it could be better, no need for shell functions.
But it has a critical flaw:
it doesn't properly preserve history.
I have `zsh` setup to incrementally add and share history between sessions,
but even without that,
kubie would lose history if i had multiple sessions open (the only reason i'd use it).

So, these days, I just use `kubeswitch`.
