# bash building args

## use arrays

### bash argument building

So I've seen a variety of ways to build up the flags to pass to a binary in entrypoint scripts.
The way I've settled on these days is to make use of arrays.
I find it looks cleaner than building up a space delimited string,
especially when you have to pass quoted values / args with spaces.
And you have less shellcheck shouting at you to use quoted arguments everywhere,
which you don't want for building up an arg string because you rely on splitting on whitespace.

```bash
#!/bin/bash

set -x

# default args
args=(
  --foo=hello
  --bar world
  --qux
)

# conditional args
if [[ ${XX} == "yy" ]]; then
  args+=( --zz )
fi

# additional args
IFS=" " read -r -a extra_args <<< "${EXTRA_ARGS:-}"
args+=( "${extra_args[@]}" )

# exec
exec some-binary "${args[@]}" "${@}"
```
