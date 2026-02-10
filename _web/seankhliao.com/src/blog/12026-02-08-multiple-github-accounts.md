# multiple github accounts

## juggling multiple accounts

### _github_ accounts, multiple of them

I'm now in the unfortunate position of having to juggle multiple github accounts for work.
(1 enterprise managed user, 1 regular user).

To keep me sane wrt to git access, I have a giant block of git credential dispatching
in my gitconfig:

```gitconfig
[credential "https://github.com/org1"]
  useHttpPath = true
  helper =
  helper = /path/to/auth.sh user1
[includeIf "hasconfig:remote.*.url:https//github.com/org1/**"]
  path = user1.gitconfig
  ; in each user.gitconfig
  ; [user]
  ;   email = me@example.com
  ;   name = My Name
  ;   signingKey = ....

[credential "https://github.com/org2"]
  useHttpPath = true
  helper =
  helper = /path/to/auth.sh user2
[includeIf "hasconfig:remote.*.url:https//github.com/org2/**"]
  path = user2.gitconfig
```

Where `auth.sh` is a [git credential helper](https://git-scm.com/docs/git-credential).

```sh
#!/bin/bash

echo "protocol=https"
echo "host=github.com"
echo "username=$1"
echo "password=$(gh auth token --user $1)"
```

The native `gh` git credential helper is can't switch user dynamically
based on the repo you're interacting with,
so this does it for me.

Using `hasconfig:remote.*.url:...` also means I'm less constrained by on disk layout
when checking out files.

Note the differences in prefix matching for credential vs a glob for includeIf ...
