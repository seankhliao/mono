# repos

repos is a tool to manage local repos.

## install

```sh
$ go install go.seankhliao.com/mono/cmd/repos@latest
```

Add the following in shell config:

```sh
function repos() {
    local out=$(command repos "$@")
    # source <(<<< "${out}")
    eval "${out}"
}
```

## usage

### creete a new temporary repo

If `name` isn't provided, the repo is created in `~/tmp/testrepoXXXX`,
where XXXX is an autoincrementing number.
The repo comes with a readme, license (MIT), and `go.mod`.

```sh
$ repos new [name]
```

### switch to the latest temporary repo

```sh
$ repos last
```

### sync all repos with HEAD

Sync all repos in first level child directories to HEAD.

```sh
$ repos sync
```

### sync non archived repos from a github user/org

Clone a copy of all non-archived github repos,
and update existing repos to HEAD.

```sh
$ repos syncgh
```
