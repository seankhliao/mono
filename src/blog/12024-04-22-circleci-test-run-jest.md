# circleci tests run jest

## what's this javascript test framework?

### _circleci_ test run with jest

[CircleCI](https://circleci.com/)
have this feature called [rerun failed tests](https://circleci.com/docs/rerun-failed-tests/).
Using _magic_, only a portion of your flaky test suite is run again.

That _magic_ is having your tool generate a list of tests,
filter it through `circleci tests run`,
and execute the tests that are still left,
writing the results to a JUnit style results file.

I was tasked with running [jest](https://jestjs.io/) tests through this,
but the jest setup I had didn't look much like the example config:

```sh
$ jest --ci --selectProjects svc
```

It took me quite a while to figure out that what I needed was the below snippet,
since our jest setup had different projects that specified the test files to run 
(for the first invocation to find the right tests)
but also global and project setup and teardown functions
(for the second invocation to run tests correctly).

```sh
$ jest \
    --ci \
    --selectProjects svc \
    --listTests | \
  circleci tests run \
    --verbose \
    --command "xargs jest --ci --selectProjects svc --runTestsByPath --"
```

Additionally, if you used circleci's native parallelism,
but can't use circleci's test splitting because it never finds the right timings,
then you need to override its default sharding behavior.
This uses jest's sharding in place of circleci's sharding:

```sh
$ jest \
    --ci \
    --selectProjects svc \
    --shard "$(( CIRCLE_NODE_INDEX + 1))/${CIRCLE_NODE_TOTAL}" \
    --listTests | \
  circleci tests run \
    --verbose \
    --total 1 \
    --index 1 \
    --command "xargs jest --ci --selectProjects svc --runTestsByPath --"
```
