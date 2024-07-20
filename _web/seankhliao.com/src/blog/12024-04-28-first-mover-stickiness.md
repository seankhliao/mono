# first mover stickiness

## your choice matters

### _first_ mover advantage

Over the past several months,
I've been on a big migration project.
Initially, we were given an impossible deadline,
well we knew it was impossible,
but we still had to work towards it,
and that meant a lot of runbooks that instructed you on clickops.

A few practice runs later,
we observed the lack of confidence in the oncallers in making these changes,
and given a slightly delayed date, we had time to start writing automation.
This initial round was in shell scripts,
some as complete scripts, others as snippets to be copy and pasted from runbooks.
It was fun finding out that a script was written to only work in zsh...

Finally, we had something that was just a little too complex for bash scripts:
automating akamai changes.
Given that I was tasked with making it fast and safe,
I obviously went with writing the automation for it in Go.
Later, with much delayed deadlines,
the team decided that it may be worth rewriting parts of the automation
in a proper programming language to have pretty output.
With a large piece already in Go,
I don't think they had much of a choice,
and Go it was for everything else.
