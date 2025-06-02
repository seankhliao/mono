# finding pids

## pid with ls

### _pid_ of processes

Recently I found myself needing to figure out the pid of a process.
My go to tools of: `htop`, `top`, `ps` weren't available.

Some searching around later,
I discovered: `ls -l /proc/*/exe`.
This expands the pids as filepaths in procfs, with the exe files being symlinks to the actual exectables.
