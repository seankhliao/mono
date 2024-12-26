# maybe not: a critical external dependency

## make your apps as self contained as possible

### _external_ dependency, maybe not

December is when everyone goes on holiday,
including me (even if I would have preferred to go when there were less people).

For the past few months
I had been experimenting with a new config setup for my personal applications:
they would get a single flag for "config location",
pointing to a [GCP cloud storage bucket](https://cloud.google.com/storage?hl=en),
and from there, they would pull down a config file containing config and secrets.

As a config file, 
this sat in the critical path for application startup;
the application wouldn't know which sub-services to run without he config file.
Having used a GCP cloud storage bucket,
my application used [workload identity federation](https://cloud.google.com/iam/docs/workload-identity-federation)
to turn its local Kubernetes service account identity into something GCP trusted.

Unfortunately for me,
I appear to have pushed some last minute code changes before I left on vacation,
and didn't check for my application to stabilize.
For the next 2 weeks,
the application was in CrashLoopBackoff as it timed out exchanging identities with
[GCP Security Token Service](https://cloud.google.com/iam/docs/reference/sts/rest).

I "fixed" it by updating my deps and redeploying. 
I don't know why that worked.

*Lesson learned:*
do not introduce unnecessary external dependencies into your application
if it can be avoided.
I'm going to look at pulling out the dependency on Cloud Storage for config and secrets
and maybe look at local first storage options for data as well.
