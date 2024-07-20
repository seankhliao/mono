# tools of work

## current short snippets of work related tooling

### _tools_ of work

While I somehow manage to run a linux setup for both my personal and work laptops (IT doesn't like me),
even sharing the majority of configs [home version at seankhliao/config](https://github.com/seankhliao/dotconfig),
the environments are still different and I thought I'd like to document some more customized workflows.

#### _many_ productions

Over the past few years, 
an explicit goal of our group/team at work was to move from a world of a single production environment,
to one of many,
each with its own set of attributes, such as region, tenancy, application set.
This necessiated local tooling that could work comfortable across environments.

##### _kubectl_

Kubernetes' main  cli, `kubectl` has native support for multiple clusters / users / contexts in its config file.
However, switching between contexts is clunky with `kubectl config use-context $context`,
I often wanted to work across multiple clusters in parallel.
Additionally some of our clusters were behind [Teleport TLS Routing](https://goteleport.com/docs/architecture/tls-routing/)
(Teleport is a mTLS solution, which is broken if you run a TLS terminating proxy in between, this tunnels through that),
necessitating the use of either `tsh kubectl` (and its different argument parsing) 
or `tsh proxy kube $cluster` and temporary generated kubeconfig.


Externally there's [kubectx](https://github.com/ahmetb/kubectx) which provides an interactive experience in selecting
the right context.
It also comes with `kubens` to switch namespaces within the cluster.
Alternatively, there's also [kubie](https://github.com/sbstp/kubie) which generates temporary kubeconfigs,
allowing each terminal session to be isolated.

I ended up with:
each cluster gets its own kubeconfig file in `~/.config/kube/$cluster`,
and I have a zsh function to select the right context with `fzf` and set it for the local session
by exporting to the `KUBECONFIG` environment variable.
I still use `kubens` for switching namespaces within a cluster.

To handle the teleport clusters,
I realized that the temporary kubeconfig files it created for `tsh proxy kube` actually had a stable naming convention
based on the port it was listenening to,
so I only had to pass the `--port` flag to a predesignated port,
and I could symlink the generated kubeconfig file.
The symlink would be broken when `tsh proxy kube` wasn't running,
but that just meant I had to start it prior in some background session.

##### _argocd_

ArgoCD has a local cli, and I ended with a similar setup as `kubectl`:
each context gets its own file, and I select between them by setting `ARGOCD_OPTS=--config=...`.

##### _yolo_

By naming the files I use for `kubectl` and `argocd` the same,
I could set the context for both,
enabling me to write a simple script to run commands across multiple clusters.
It's called yolo because of how dangerous it can be (especially with all my admin access).

#### _git_

I've done comparatively much less customization on `git` itself.
Instead I'll just describe the workflow.

_Linear_ history: 
the only option we allow for merging PRs on Github is "squash and merge".
since we do continuous deployment, 
I think it more accurately reflects reality,
in that only a single history is fully tested and deployed.

_Short_ lived branches: 
each PR / branch exists only for a single feature,
and usually only for minutes to days. 
Usually there's only a single owner pushing to it.

_Rebase_ workflow: 
since we squash and merge, 
it doesn't really matter if you merge or rebase your changes with main,
since it's all squashed away in the end,
but I prefer rebases as it makes the PR commits look less cluttered.
However, Github doesn't always track the changes well.

_Worktrees_:
since it can be somewhat common to have multiple in progress things at once
(especially with incidents on a repo you're working on),
and still be able to refer to the current state of the repo easily,
I prefer using `git worktree` for each branch.

_Stacked_ PRs:
generally avoided,
since Github can't track conflict resolutions well,
rebasing an earlier PR will likely break your stack and you have to go fix each one individually.
Plus updating the refs when they're checked out in worktrees are a pain.
I miss Gerrit.

_Titles_;
generally includes a ticket reference,
and a description of what.
Conventional commits don't really do much for our team so we skip, though other teams do enforce it.
Sometimes the PR will contain some motivation,
if someone remembered, the repo will be configured to use the PR description for the merge commit message.

_pre-commit_:
something we use to make shift bad change detection earlier,
but making sure everyone has it installed is... not easy.
We use it for tests and formatting.
