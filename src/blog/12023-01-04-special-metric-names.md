# special metric names

## why inline things can get confusing

### _special_ metric names

Today, a coworker reported that they had added a counter metric `project_monitor_created`
but it wasn't showing up in our metrics backend (datadog).
The other metrics from the service were all going through fine,
so why not this one?

For context, our metric collection system consists of:
application exposing metrics in prometheus exposition format at `/metrics`,
[OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
scraping and doing a delta conversion,
[Vector](https://vector.dev/) doing some extra transformations,
and finally sending it to Datadog.

First, we verify that the application is actually producing the metric
(`curl localhost:8080/metrics`)
and that it's increasing.

We first suspect `vector`,
because it's usually the one with problems.
But running `vector tap` on the pipeline just shows it getting data points with `value: 0.0`
(if we didn't crash our teleport agents when trying to dump all that data).

So we move back a stage into the collector.
Adding a [`debuge`](https://github.com/open-telemetry/opentelemetry-collector/tree/main/exporter/debugexporter)
wasn't too hard,
I also used a [`filter`](https://github.com/open-telemetry/opentelemetry-collector-contrib/tree/main/processor/filterprocessor)
to only include the metric I wanted:

```yaml
connectors:
  forward:

processors:
  filter:
    metrics:
      metric:
        - name == "project_monitor_created"
exporters:
  debug:

services:
  pipelines:
    mettrics/original:
      receivers:
        - prometheus
      processors:
        - cumulativetodelta
        -  # others
      exporters:
        - forward

    metrics/debug:
      receivers:
        - forward
      processors:
        - filter
      exporters:
        - debug
```

The output of this also showed data points with `Value: 0.0`.
So the problem was even earlier in the stack.

Instead of pulling from the final output stage,
we can use the output of the `prometheus` receiver directly in our debug pipeline.

This finally has something interesting:
The data point value is still `Value: 0.0`,
but it has a `StartTimestamp: 1970-01-01 00:00:03`.
This gave me a decent idea of what was happening:
even though the receiver is called a prometheus receiver,
prometheus metrics can be a bit too loosely typed.
So there's the [OpenMetrics](https://openmetrics.io/) project that tries to formalize it,
and in the process, introduced some extra features.

If you look at the [OpenMetrics spec](https://github.com/OpenObservability/OpenMetrics/blob/main/specification/OpenMetrics.md)
you can find that `_created` is a [suffix for counters](https://github.com/OpenObservability/OpenMetrics/blob/main/specification/OpenMetrics.md#suffixes)
along with the following quotes:

> A MetricPoint in a Metric with the type Counter SHOULD have a Timestamp value called Created.
> This can help ingestors discern between new metrics and long-running ones it did not see before.

> The MetricPoint's Total Value Sample MetricName MUST have the suffix "\_total".
> If present the MetricPoint's Created Value Sample MetricName MUST have the suffix "\_created".

So our collector has decided to treat the value as a start Timestamp
for a metric we don't have a value of.
Once we found this,
it was a relatively easy fix of renaming the metric.
