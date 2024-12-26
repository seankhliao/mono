# maybe not: a monolith

## so that's why people do microservices

### _monolith_, maybe not

Related to [my previous post on external dependencies](../12024-12-23-maybe-not-critical-external-dependency/),
what made my situation a bit worse was another experiment I was running with:
a monolith.

Sometimes people online say things like monoliths are actually fine,
you just need proper code discipline to maintain boundaries between different sections of code.
Well as the only person working on this, that was quite easy.

However, fundamentally, my monolith was a collection of mostly unrelated services,
and it meant that a failure in one service brought down the entire thing,
including quite a few unrelated services that could have otherwise kept running.

*Lesson learned:* I will be looking into splitting up the services again.
Though I'll seriously consider writing my own deployment tool first...
