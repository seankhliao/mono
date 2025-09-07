# flag or env var

## how do you pass a config option

### _flag_ or env var

As much as we all like zero-config applications that just work,
sometimes we do have to pass them config options.
The common ways to do so in increasing order of priority (most of the time):
config files, environment variables, and flags.

While it's nice that config files can have comments,
I find that they're a pain to manage / merge properly in automated deployments.
You see this often with ansible scripts where it tried to find some option to change it,
you'd better hope the option is well named that it can easily be found in the right section.

The [12 factor app](https://en.wikipedia.org/wiki/Twelve-Factor_App_methodology)
methodology says config should be using env vars.
I certainly use this for secrets,
which you don't want to be accidentally logged.

Flags show up in a process's command line.
This can be good: easy to see / log what the program started with,
but at the same time, you probably don't want to pass secrets like this.
Flags are also generally better documented,
and easier to copy around.

Side story:
recently I ran some software that worked as a supervisor process and ran a child process
(`foo-bar`).
Turns out the supervisor will crash when it (re)starts the child process,
but finds some other process running on the system with the name of process in it's command line.
For example, we had a process with the flag `--foo-bar-compatible`.
Never have I been so thankful that the process could also be configured with environment variables.
