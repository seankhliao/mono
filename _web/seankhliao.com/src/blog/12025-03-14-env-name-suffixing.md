# env name suffixing

## err name too long

### _env_ name suffixing

There are cases where you have the same app 
deployed in different environments or as different instances,
but you need a list of them across all environments,
with unique names.
Maybe you use a shared backend?

Anyway, many places have arbitrary name length limits.
So you might run into an issue like:

```
dev-my-app                     // ok
prod-my-app                    // ok
my-werid-custom-env-my-app     // error, name too long
```

I think if you ever need to do so,
environment / variant names should have consistent lengths,
that way you can also cap application names to a fixed length.
Maybe something like:

```
dev-
prd-
c01-
```

