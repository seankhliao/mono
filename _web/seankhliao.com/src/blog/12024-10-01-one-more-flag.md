# one more flag

## does it hurt to add another option?

### _just_ add another flag

As a maintainer of libraries both at work and in open source software,
there are not infrequent requests to add new config options.
The users requesting the extra config will have their own reasons:
it's too much effort to change their code,
we have this special snowflake workflow that we want to support,
this is the path of least resistance, etc.

Well first we have to praise them for not being constrained by current realities,
and realizing that changing libraries and platforms is an option.
However, we will also often have to turn down these requests.
While each individual option may only have a minor impact,
with many of them, their interactions can be complex,
and the full problem space may not be testable.
For the user, they may just want to get their next feature out the door,
but for the maintainers,
long term sustainability is much more important,
as each branch complicates the scenarios to test when performing future upgrades.

So you have to say no,
gently, but firmly.
Sometimes the requestor can get frustrated and angry,
but what can you do?
For corporate code,
it may very well be that you have access to the entire set of your dependants,
and can initiate large scale changes that can reduce the config options you need to support.
For open source code, a lot of your users may be in private codebases that you never see,
and you're forever stuck with any additions:
deprecations are mere suggestions,
you only get a reset when you declare bankruptcy and start a new major version.
