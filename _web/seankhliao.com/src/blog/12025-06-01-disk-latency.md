# disk latency

## the unmentioned disk stat

### _disk_ latency

For my dayjob as an SRE,
I manage various services we didn't write.
Recently, I was investigating the performance of some ... database like service.

Background: this service stores a lot of data directly on disk (a few TB),
and runs transforms on partial data and stores the result.
For easier management, we run it on AWS in EKS with StatefulSets,
with their disk being EBS volumes.

Trigger: the service hasn't been performing as well as it should,
it's not keeping up with the replicas run by our partners (on bare metal).

Initial response: the first few incidents,
the responses were: restart, run a slightly different mode,
give it more cpu / memory,
set the EBS volume to io2 (Block Express) and bump up IOPS.

My turn: so I'm on call,
and it still breaks.
I switch the machine type to the fastest cpu available
(AWS EC2 r7iz @ 3.9Ghz vs our default c7a @ 3.5Ghz)
and start investigating.

Looking at processing progress,
our replicas start falling behind at similar but different points in time,
and roughly keep the same amount of lag for some time before finally catching up.
So something about the data it's processing is causing it to fall behind,
and it's likely already executing as fast as it can.
The faster cpu seems to only have been a minor improvement though.

Since the software is written in Go, with [pprof](https://pkg.go.dev/net/http/pprof) available,
I decide to grab a trace and look at it with [gotraceui](https://gotraceui.dev/).

```bash
# gotraceui needs to be built from source on master for recent Go programs
$ git clone https://github.com/dominikh/gotraceui
$ cd gotraceui
$ export CGO_ENABLED=1
$ go install ./cmd/gotraceui

# grab a trace from the service, pprof on port 6060
# start a cpu profile in the background
$ curl -o /dev/null 'http://localhost:6060/debug/pprof/profile?seconds=124' &
$ curl -o trace.out 'http://localhost:6060/debug/pprof/trace?seconds=120'

# view the trace
$ gotraceui ./trace.out
```

Looking at it was illuminating:
our program was highly concurrent with 860 goroutines at peak,
but only 1 "hot" goroutine doing the main processing work (simulating a single threaded VM).
Focusing on said goroutine,
it had short burst of execution, blocked by long calls to `syscall.read`.

Adding more cpu does not help:
our core process is single threaded and won't take advantage of more processors.

Switching to a fast cpu had a minimal effect:
due to Amdahl's Law,
it means if we were only actually executing ~20% of the time,
with 80% waiting for a disk read,
our 11% CPU speed up is in effect more like a 2% overall speed up.

More IOPS in EBS does not help.
AWS target "low-variance sub-millisecond disk I/O latency" with io2 Block Express.
Indeed we see our AWS reported metrics reporting around 0.5ms average read latency.
But we don't need more reads in the same time frame, we need faster reads
(reads can be scaled by doing them in parallel).
But that should be compared to local disks which should give us < 100 microsecond (0.1ms).

Given our access is mostly random with almost no queue depth to speak of,
what we need is lower disk latency.
Unfortunately, that means a local SSD (instance store in AWS),
and all the pain of managing data on that.
I did find a [blog post from Discord](https://discord.com/blog/how-discord-supercharges-network-disks-for-extreme-low-latency)
on how they also need similar low latency,
but also liked the management of network disks better,
so they setup RAID1 across a local diska and remote.
Also, maybe with enough memory,
the linux kernel will cache enough of the pages we need for us...

We shall see what we end up doing.
