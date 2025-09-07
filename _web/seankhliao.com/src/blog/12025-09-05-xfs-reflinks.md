# xfs reflinks

## fast copies?

### _xfs_ reflinks

We have some software that is disk IO latency sensitive.
In AWS, this means we run it on `i4i` instance types.
We also need snapshots of the data on disk,
looking at the available options,
we went with using XFS as the filesystem,
and using reflink copies (`cp --reflink=always`).
This should be fast, reusing the filesystem blocks,
and making the original a copy on write.
This should have allowed us to get an immutable copy
without doubling the disk space used.

The dataset I have to work with is currently 5.7TiB,
in 660 files, one of which is a single file DB at 3.7TiB.
I recall the first time, the copy was fast, completing within a 5 minte timeout.
Over time, it appears to have slowed down,
last I checked it took 31 minutes.

Thinking about it,
I think it has to do with the single file db,
and the underlying blocks (extents).
The first time, it's a simple range (0-end),
but the copy on write means the underlying extents get more fragmented,
and the future copies have to copy increasingly complex ranges.
