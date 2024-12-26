# maybe not just tracing

## are traces all you need?

### _tracing,_ but you still need other signals

In the observability space, there are many signals that you can use to observe your application,
though the most common ones are: logs, metrics, tracing, and profiling.

Maybe I drank a bit too much vendor kool-aid,
but I thought maybe traces were all I needed.
After all, they carry pretty much the same, 
if not more information than logs,
and you can derive metrics from the trace spans.
Earlier in the year, 
I had even [experimented with a trace-first api](../12024-03-17-tracing-spans-as-logs/) 
for producing both spans and logs form a single call.

But... my [weeks long application failure](../12024-12-23-maybe-not-critical-external-dependency/)
this month generated no spans at all,
because tracing config was in the config file,
and my application failed to even retrieve the config file in the first place.
I only understood the problem when I looked at logs,
(which I hadn't been collecting so it meant running kubectl).

So you can't rely on traces for everything,
well maybe if you set it up early enough and flush before exiting,
but maybe it's still best to have the other signals.

Next I'm considering leaning into wide events.... 
but I still don't think there's a good open source backend for storing and quering them.
