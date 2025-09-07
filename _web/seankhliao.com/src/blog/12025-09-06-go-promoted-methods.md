# go promoted methods

## shadow...

### go promoted methods

In Go, if you embed a type in a struct,
its methods can get promoted.

#### refactors

While it's something you usually remember and avoid by not embedding fields,
here's an example of how I ran into it while refactoring.

##### starting point

We start with a config struct, including some identifiers.
On startup, we log the config,
elsewhere, we use the struct fields.

```go
type Config struct{
  // ...
  Name string
  Instance string
}

// used as
func foo(c Config) {
  slog.Info("started", "config", c)
  fmt.Println(c.Name)
  slog.Info("id", "name", c.Name, "instance", c.Instance)
}
```

##### grouping fields

Later I realized the fields were always used together,
and I wanted to do an easy comparison with `==`,
so I put them in a struct.
Being too lazy to update all the references,
I used an embedded field and let the struct fields be promoted.

```go
type Config struct{
  // ...
  ID
}

type ID struct{
  Name string
  Instance string
}

// used as
func foo(c Config) {
  slog.Info("started", "config", c)
  fmt.Println(c.Name)
  slog.Info("id", "name", c.Name, "instance", c.Instance)
}
```

##### logging helper

Later while adding more logs,
I added a `slog.LogValuer` method.
Unfortunately, this is where the bug was.
I consciously wanted struct field promotion,
but I forgot about method promotion,
so logging the config turned into only logging the id...
The fix was to not be lazy,
and make it not an embedded field (and update all the references).

```go
type Config struct{
  // ...
  ID
}

type ID struct{
  Name string
  Instance string
}

func (i ID) LogValue() slog.Value {
  return slog.GroupValue(
    slog.String("name", i.Name),
    slog.String("instance", i.Instance)
  )
}

// used as
func foo(c Config) {
  slog.Info("started", "config", c)
  fmt.Println(c.Name)
  slog.Info("id", slog.Group("id", c.ID))
}
```
