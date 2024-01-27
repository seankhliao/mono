# config or data or code

## blurry lines on single user systems

### _config_ data code 

Stateless systems are easy to manage:
they're authored in code to have some limited amount of configurable behaviour,
while data comes in and goes out with a processing request.

Stateful systems can be a bit more complicated:
they might start up with just config,
but often times they're in some sort of setup mode,
where it needs data to be initialized to work properly.
This is more apparent in generic stateful systems like databases, 
they need schemas, users, and maybe some seed application data
before they're useful.

Single user systems are even more fun.
It can be very tempting to specify the setup for the only user
as part of the config,
doubly so if the config is dynamic or is actually a bunch of scripts.

Now, where does the border lie wit infrastructure as code?
Do you just provision the system with config,
and leave data setup to something else?
Or do you try to encode the data setup somehow in a declarative way?
