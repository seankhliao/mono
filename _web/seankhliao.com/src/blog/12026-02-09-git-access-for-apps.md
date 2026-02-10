# git access for apps

## how do you use that install token

### _git_ access for apps

Say you've created your
[github app](https://docs.github.com/en/apps/creating-github-apps/about-creating-github-apps/about-creating-github-apps),
now you want to use it to clone a git repo.
How do you do that?

You might see things like `https://x-access-token:$token@github.com/owner/repo`,
But that's sort of fiddly,
and you risk leaking your token if you log the url.

A better way would be to use an [askpass program](https://git-scm.com/docs/gitcredentials/2.26.0).

Given the environment variables `GIT_ASKPASS=askpass.sh` and `GIT_ASKPASS=askpass.sh`,
`git` will invoke `askpass.sh` (in `$PATH`) twice:

```sh
askpass.sh "Username for ..."
askpass.sh "Password for ..."
```

With that, we can construct a simple script to match on the argument,
and print out the username and password,
passed via environment variable to the script:

`askpass.sh`:

```sh
#!/bin/sh

case "$1" in
Username*) echo "${GIT_USERNAME}" ;;
Password*) echo "${GIT_PASSWORD}" ;;
esac
```

Using it from go might look like:

```go
package main

import (
        "context"
        "os"
        "os/exec"
)

func runGit(ctx context.Context, token string, args ...string) {
        c := exec.CommandContext(ctx, "git", args...)
        c.Env = append(os.Environ(),
                "GIT_ASKPASS=askpass.sh",
                "GIT_USERNAME=git",
                "GIT_PASSWORD="+token,
                "GIT_TERMINAL_PROMPT=0",
        )
        b, err := c.Output()
        // ...
}
```

Note that this is different from a git credential helper.
