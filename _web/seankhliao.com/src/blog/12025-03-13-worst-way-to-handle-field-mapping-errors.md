# worst way to handle field mapping errors

## unstructured objects and types

### _field_ type mapping errors

Structured logs are a great thing,
you can search log lines by different attributes.
Unfortunately, most log systems seem to want to work on typed data,
it expects fields of the same name to have the same type.

```json
{"time": "2025-03-16T00:00:01", "foo": "bar", "msg": "hello world"}
{"time": "2025-03-16T00:00:02", "foo": 1, "msg": "fizz buzz"}
```

With the above log lines,
logging backends may throw errors.
Both OpenSearch and Datadog will complain.

Thankfully, most applications are consistent within themselves,
it's different applications using the same name that's a problem.

There are many options to handle this,
one might be to have a schema and filter out non matching attributes,
or having a dedicated index per application,
or mutating logs to group attributes under the application name like:

```json
{"time": "2025-03-16T00:00:01", "app1": {"foo": "bar"}, "msg": "hello world"}
{"time": "2025-03-16T00:00:02", "app2": {"foo": 1}, "msg": "fizz buzz"}
```

I've recently seen a most terrible way to handle this,
stringify all custom values.
I don't know how you use logs like this:

```json
{"time": "2025-03-16T00:00:01", "values": "\"foo\": \"bar\"", "msg": "hello world"}
{"time": "2025-03-16T00:00:02", "values": "\"foo\": 1", "msg": "fizz buzz"}
```
