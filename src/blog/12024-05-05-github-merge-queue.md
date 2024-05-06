# Github merge queue

## rebase all the things

### _github_ merge queue

You may have heard about merge queues before.
[Bors](https://github.com/bors-ng/bors-ng)
was one implementation,
[Mergify](https://mergify.com/merge-queue)
was a dedicated app to do it.
A while back,
Github's [native merge queue](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/configuring-pull-request-merges/managing-a-merge-queue)
went [generally available](https://github.blog/2023-07-12-github-merge-queue-is-generally-available/)
(but only for enterprise and orgs).

At a very high level,
you hand commits you want to merge to the merge queue,
and it figures out a safe ordering to do so,
where safe means the final state of the target branch has always passed CI.

While looking at Github's implementation,
what surprised me was how it didn't really reduce the number of builds required.
Given how merge queues are sold as allowing a greater number of merges into a branch,
I had thought that the batching would be a more integral part of the merge queue.

Below I've included a diagram that helped me map out the concepts of
Github's merge queue:

![github merge queue](/static/github-merge-queue.png)
