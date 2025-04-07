# pruned module graph

## slimmer modules graphs

### _pruned_ module graph

I haven't had a very clear idea of what Go 
[Module graph pruning](https://go.dev/ref/mod#graph-pruning)
actually meant.

Some notes:

* `go list -m all` shows the full set of dependency
* `go list all` only shows packages in the pruned dependency graph
* `go.mod` only contains modules in the pruned dependency graph

Example set of modules in a similar structure:
[github.com/seankhliao/testrepo1125](https://github.com/seankhliao/testrepo1125).

I tried to draw a graph (unrelated to the repo above):

![module graph](/static/pruned-module-graph.png)
