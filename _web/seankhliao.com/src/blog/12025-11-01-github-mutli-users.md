# github multi users

## because auth is hard

### _github_ multi user auth

Say you're forced to use different github users on a single machine.
You need a way for your commits to be authored by the right user,
and clone/fetch/pushes to also use the right credentials.
Say for a given repo, it will always use a specific user.

For auth via ssh,
you have to do the ugly hack of using git config to rewrite a hostname,
then using ssh config to rewrite the hostname again,
but with the right ssh key.

For auth via https,
it is in theory better since you can specify a username...
but you still need some way to get a valid token.
Unfortunately, the `gh` cli's native setup isn't very helpful:
[can't get a token for a different user](https://github.com/cli/cli/issues/9111),
[fails if it's not the current user](https://github.com/cli/cli/issues/11938).

#### _commit_ identity

When authoring commits,
we need some way to set the right author.
We'll make use of conditional includes, specifically
[`hasconfig:remote.*.url`](https://git-scm.com/docs/git-config#Documentation/git-config.txt-hasconfigremoteurl),
which matches on url globs.
This is more flexible than the usual recommendation of using gitdir,
which forces a specific organization of git repos on disk.

```gitconfig
# Main git config file

[includeIf "hasconfig:remote.*.url:https://github.com/user1/**"]
  path = user1.gitconfig

[includeIf "hasconfig:remote.*.url:https://github.com/user2/**"]
  path = user2.gitconfig
```

```gitconfig
# user1.gitconfig
[user]
  email = user1@example.com
  name = user 1
  signingKey = ssh-ed25519 AAA...1
```

```gitconfig
# user2.gitconfig
[user]
  email = user2@example.com
  name = user 2
  signingKey = ssh-ed25519 AAA...2
```

#### _credentials_

For interacting with github,
there are 2 problems with credentials:

If you put the different credentials in the conditionally included files (using hasconfig:remote),
they aren't used during clones because there's no remote to match against.

The `gh` cli's native git-credential helper (`gh auth git-credential`) can only ever return
the token for a single active user.

But we can work around this by making our own credential helper!
Like the above, we'll need to do some static dispatching in our main git config,
this time using [credential contexts](https://git-scm.com/docs/gitcredentials#_credential_contexts)
which match on url prefixes.

```gitconfig
# Main git config file

[credential "https://github.com/user1"]
  helper =
  helper = "!echo \"protocol=https\nhost=github.com\nusername=user1\npassword=$(gh auth token --user user1)\n\""

[credential "https://github.com/user2"]
  helper =
  helper = "!echo \"protocol=https\nhost=github.com\nusername=user2\npassword=$(gh auth token --user user2)\n\""
```

#### _jj_ config

When using [jj](https://jj-vcs.github.io/jj/latest/),
it manages commit identity,
but delegates git auth to `git`.
So we can reuse the above part for credentials,
but we need some other way to pass the right name/email/siging key.

jj has [conditional variables](https://jj-vcs.github.io/jj/latest/config/#conditional-variables)
but we're essentially limited to on disk layout again.
[open issue for conditional based on remote url](https://github.com/jj-vcs/jj/issues/6028).

```toml
[[--scope]]
--when.repositories = ["~/user1"]
user.email = "user1@example.com"
user.name = "user 1"
signing.key = "ssh-ed25519 AAA...1"

[[--scope]]
--when.repositories = ["~/user2"]
user.email = "user2@example.com"
user.name = "user 2"
signing.key = "ssh-ed25519 AAA...2"
```
