# evil default values

## when your secret key falls back to development keys

### _default_ secrets can be evil

I was recently in an incident where we realized 
that an application was not using the secret key that we thought we had configured,
but had instead fallen back to a low entropy key that was set in its default config.

What can we learn?

Separation of config.
This application merged the config it obtained from multiple sources:
plaintext config file, secret config file, and environment variables,
to create a single config structure.
In a misconfiguration of one of the sources,
the application instead picked up a value from plaintext config.
The plaintext config should never have contained a value for a secret,
and the application should never look there for one.

Secrets should be secrets?.
For some other secrets, 
the application had entropy checks to ensure that a secret was sufficiently unguessable.
Of course, this wouldn't have stopped someone from committing a "secure" key in the default config.

Zero touch secrets.
This was a secret key that needed to be shared between multuple instances of the application,
and persist across restarts.
Instead of having a human inject a secret for the application,
it should have been possible for it to generate and persist a secret on startup if one did not exist,
eliminating the need to pass configuration at all.

Config introspection.
It was quite difficult to identify which value the application had picked up.
I would have liked some way to inspect the resolved config values,
with the appropriate masking of secrets (last n characters visible?).
