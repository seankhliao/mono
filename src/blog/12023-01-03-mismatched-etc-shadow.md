# mismatched /etc/shadow

## fixing the shadow file

### _mismatched_ /etc/shadow

I was looking at the state of my system, and saw that it was degraded:

```sh
$ systemctl list-units --state=failed                
  UNIT           LOAD   ACTIVE SUB    DESCRIPTION                                 
● shadow.service loaded failed failed Verify integrity of password and group files

Legend: LOAD   → Reflects whether the unit definition was properly loaded.
        ACTIVE → The high-level unit activation state, i.e. generalization of SUB.
        SUB    → The low-level unit activation state, values depend on unit type.

1 loaded units listed.
```

I wonder why:

```texr
Jan 06 00:00:25 hwaryun systemd[1]: shadow.service: Failed with result 'exit-code'.
Jan 06 12:44:43 hwaryun systemd[1]: Started Verify integrity of password and group files.
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'bin' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'daemon' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'mail' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'ftp' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'http' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'nobody' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'dbus' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'systemd-coredump' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'systemd-network' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'systemd-oom' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'systemd-journal-remote' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'systemd-resolve' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'systemd-timesync' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'tss' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'uuidd' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'avahi' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'geoclue' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'git' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'polkitd' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: no matching password file entry in /etc/shadow
Jan 06 12:44:43 hwaryun sh[53932]: add user 'rtkit' in /etc/shadow? No
Jan 06 12:44:43 hwaryun sh[53932]: pwck: no changes
Jan 06 12:44:43 hwaryun systemd[1]: shadow.service: Main process exited, code=exited, status=1/FAILURE
Jan 06 12:44:43 hwaryun systemd[1]: shadow.service: Failed with result 'exit-code'.
```

So checking `/etc/shadow` it really does seem as if I'm missing entries,
probably from when I failed to use `systemd-firstboot`.
So, what can we do about it?

Looking at what the failed unit does,
we find a `pwck` command that looks promising

```sh
$ systemctl cat shadow       
# /usr/lib/systemd/system/shadow.service
[Unit]
Description=Verify integrity of password and group files
After=systemd-sysusers.service

[Service]
CapabilityBoundingSet=CAP_DAC_READ_SEARCH
# Always run both checks, but fail the service if either fails
ExecStart=/bin/sh -c '/usr/bin/pwck -qr || r=1; /usr/bin/grpck -r && exit $r'
Nice=19
IOSchedulingClass=best-effort
IOSchedulingPriority=7
IPAddressDeny=any
LockPersonality=yes
MemoryDenyWriteExecute=yes
NoNewPrivileges=yes
PrivateDevices=yes
PrivateNetwork=yes
PrivateTmp=yes
ProcSubset=pid
ProtectClock=yes
ProtectControlGroups=yes
ProtectHome=read-only
ProtectHostname=yes
ProtectKernelLogs=yes
ProtectKernelModules=yes
ProtectKernelTunables=yes
ProtectProc=invisible
ProtectSystem=strict
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6
RestrictNamespaces=yes
RestrictSUIDSGID=yes
RestrictRealtime=yes
SystemCallArchitectures=native
SystemCallFilter=@system-service
SystemCallFilter=~@resources
SystemCallFilter=~@privileged
UMask=0077
```

Reading the manual entry doesn't say that it will fix things,
but given it has a `--read-only` flag,
it's natural to assume that its default mode will modify (fix?) the files.
So we take a risk and run it, 
and it prompts to fix every entry:

```sh
$ sudo pwck           
no matching password file entry in /etc/shadow
add user 'bin' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'daemon' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'mail' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'ftp' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'http' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'nobody' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'dbus' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'systemd-coredump' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'systemd-network' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'systemd-oom' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'systemd-journal-remote' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'systemd-resolve' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'systemd-timesync' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'tss' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'uuidd' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'avahi' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'geoclue' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'git' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'polkitd' in /etc/shadow? y
no matching password file entry in /etc/shadow
add user 'rtkit' in /etc/shadow? y
pwck: the files have been updated
```
