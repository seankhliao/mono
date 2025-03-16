# comments in json as arrays

## comments where they shouldn't be

### _comments_ in json

JSON doesn't natively support comments,
but if your application doesn't complain about unknown keys,
you can do something like:

```json
{
  "//": "foo does a thing",
  "foo": "hello"
}
```

If you need multiple lines,
you might consider using arrays, like:

```json
{
  "//": [
    "foo does a thing",
    "it does it really well"
  ],
  "foo": "hello"
}
```
