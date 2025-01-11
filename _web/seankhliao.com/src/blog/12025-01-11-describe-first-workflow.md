# describe first workflow

## announcing your intentions before you start working

### _describe_ first

$work published some stats for [Github Copilot](https://github.com/features/copilot)
(after nearly forcing us to turn it on),
and from the stats, I saw that I was one of 2 people using it with [Neovim](https://neovim.io/)
(+1 on Vim) out of 300 people who had tried it.
It also showed us neovim users had a 2% acceptance rate for completions,
far below the ~30% of VS Code or JetBrains users.

Thinking about this with some friends,
I think it's partly driven by the way I work:
I jump stright in to making the changes,
then at the very end, I maybe write a comment to describe why.
This seems quite different from the prompt driven workflow
where you describe your desired function first,
and let the agent fill in the implementation.
My understanding of general consensus was that comments describing what/how
were useless / redundant with the code and would go out of date,
while the reasoning would be more useful to the future reader.

About that change first flow,
one of my most used shell aliases supports that:
`wt` (short for "worktree")
allows me to grab any uncommitted changes on the default branch of a repo checkout
and move them to a new git worktree or [jj](https://github.com/jj-vcs/jj) workspace to continue working.
This comes from my habit of hacking on the current state of the repo,
before deciding that it's work worth committing.

Talking of [jj](https://github.com/jj-vcs/jj),
some of its proponents also advocate for a describe first workflow:
They do `jj describe` on an empty commit, then start working.
I'm still pretty much a describe after person,
I rarely touch `jj describe`,
instead preferring `jj commit` after I've made changes,
and liberal use of `jj squash` to make changes afterwards.

One last thing it reminded me of was 
[Readme Driven Development](https://tom.preston-werner.com/2010/08/23/readme-driven-development),
I remember trying it a few times,
and giving up as I'd rather have something that works first.
