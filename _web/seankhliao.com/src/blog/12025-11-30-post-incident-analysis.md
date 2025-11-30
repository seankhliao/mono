# post incident analysis

## how do you think about failures

### _incident_ postmortem analysis

**This post mostly serves as a place to link to good posts.**

Recently I've been annoyed at having to do "[Five whys]" incident postmortem analysis.
If you just read the literature on them,
you might think it's a decent idea:
peel back layers of why something failed,
and end up with _some_ root cause.

Note _some_ root cause.
The true way may have you drawing fishbones,
or trees, or directed acyclic graphs
(I'm not even convinced on the acyclic part),
and ending up with any number of root causes.
Which is probably fine.

But like [Scrum] and [Agile] before it,
once adopted by the corporate world,
it's contorted into something else.
There's usually some standard postmortem template you have to fill out,
and it's a list (or table) of "Why" x 5.
Choose the story you want to tell,
and at the end pops out a root cause (usually singular).

The 5 Whys model is pretty subjective,
different people will likely end up with different results for root causes,
or even more likely, each will choose a single root cause.
The depth of 5 is also pretty arbitrary,
though some people might say you adjust that as necessary
that just feeds in to the prior point of it not being reproducible.

[Five whys]: https://en.wikipedia.org/wiki/Five_whys
[Scrum]: https://en.wikipedia.org/wiki/Scrum_(project_management)
[Agile]: https://en.wikipedia.org/wiki/Agile_software_development

#### _root_ cause analysis

In my opinion,
the idea that there even is a root cause is questionable.
Read [Root Cause Analysis? You’re Doing It Wrong].

Rather, in the complex systems we manage,
there's usually different safeguards built in at different layers.
At the very least the [Swiss cheese model] is a better representation,
but even then, it's still too simple.

The stars have to align for all the controls to fail.
The incident happened because the final check lapsed,
but before then multiple things might probably already have gone wrong
for an extended period of time.

Think less that there are any "root causes".
There are only contributing factors,
[each necessary, but only jointly sufficient]
only immediate triggers,
and _contributing factors_ that lead to the current state.

[Root Cause Analysis? You’re Doing It Wrong]: https://entropicthoughts.com/root-cause-analysis-youre-doing-it-wrong
[Swiss cheese model]: https://en.wikipedia.org/wiki/Swiss_cheese_model
[each necessary, but only jointly sufficient]: https://www.kitchensoap.com/2012/02/10/each-necessary-but-only-jointly-sufficient/

#### _complex_ systems

If we take a step back,
we're usually trying to manage a complex system:
observing a failure state,
and introducing controls to prevent that class of error states from reoccurring.

[How complex systems fail],
this is probably the most accessible way to think about systems failures.
Systems are dynamic, and probably in some kind of error state most of the time.

"System Theoretic Accident Model and Processes (STAMP)"
and "System Theoretic Process Analysis (STPA)"
are some more well rounded approaches to modeling failures,
which leads in to the [Causal Analysis based on System Theory (CAST) handbook].
The handbook is dense though,
so a shorter summary can be found at [Causal Analysis based on System Theory].

Google SRE is also shifting in this direction,
with their 2024 post [The Evolution of SRE at Google]
and [Teaching a new way to prevent outages at Google],
which expands on why they model with STPA.

[How complex systems fail]: https://how.complexsystems.fail/
[Causal Analysis based on System Theory (CAST) handbook]: http://sunnyday.mit.edu/CAST-Handbook.pdf
[Causal Analysis based on System Theory]: https://github.com/joelparkerhenderson/causal-analysis-based-on-system-theory
[The Evolution of SRE at Google]: https://www.usenix.org/publications/loginonline/evolution-sre-google
[Teaching a new way to prevent outages at Google]: https://sre.google/stpa/teaching/
