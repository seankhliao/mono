# compressible memory

## memory is a gas

### _memory_ is compressible

Recently for work, I was looking at adjusting the resource allocations for our services.
We kind of knew our kubernetes pods were overprovisioned,
but by how much exactly?

The straightforward answer is to look at cpu and memory utilization
and adjust the requests / limits down to that.

But how much memory do you actually need?
At work I have access to Datadog, which gives me a `container.memory.usage` metric.
But it includes things like disk pages that the kernel caches on your behalf,
you can force it to not use so much cache by limiting the memory.
We look at `container.memory.rss` and `container.memory.working_set`
which depending on the process might be anywhere from 20%-100% of `container.memory.usage`,
and align our resource requests/limits to that.

