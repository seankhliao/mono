# logs as text vs events

## formalized printf debugging

### _logs_ as text vs events

I think there's a split in how observability tools want you to think about logs.

On the one hand are tools that treat logs as part of a coherent stream,
each entry is likely in some way to relate to the previous or later entries,
and together they tell a story of what happened.
Tools like this will have an easy of getting from a specific entry to the surrounding ones,
and will prioritize displaying the stream over individual log lines.
Things like loki and google cloud logs falls into this category.

Then there's the wide events bag of attributes type,
like those processed by OpenSearch or Datadog.
I think here the display of multiple related events to record a timeline is severely crippled,
instead prioritizing search for a single event (or similar events),
and hoping that gives you enough information to understand what happened.

I felt this most acutely with CI / scripting tool output.
The output log lines of these individually don't carry much information,
it's together that they show what happens,
and I'd hate to read them in a tool like Datadog.
