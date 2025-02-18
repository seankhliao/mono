# bucket filesystems aren't enough

## mmap for the big files

### _bucket_ filesystems aren't enough

For the past few months, 
I've been trying to rely less on direct filesystem access littered throughout my code,
instead passing in handles to filesystem abstractions,
whether that's [io/fs.FS](https://pkg.go.dev/io/fs#FS) or 
[gocloud.dev/blob.Bucket](https://pkg.go.dev/gocloud.dev/blob#Bucket).

It was fine for the first few apps I (re)wrote,
but then I had a use case that pulled in slightly more data.
It wasn't a lot, and the machine I was running on was kind of small with 16GB of RAM,
but it did make me realize that it probably wasn't sustainable to rely on
reading the full object in, updating it, and writing the whole thing out.

What's next?
My first though was a database,
I don't really fancy running a separate deployment (e.g. postgres),
so maybe SQLite,
though I kind of don't want to write SQL either...
Maybe I'll just just a KV store like pebble.
