# pushing artifacts is slow

## push full fat binaries

### _pushing_ artifacts is slow

These days I've been using [ko](https://ko.build/)
to build my containers.
While it's simple to configure and fast to build,
working a lot from coffee shops and other remote locations using mobile connections,
I've come to realize a big disadvantage of this workflow:
I have to push up fully built go binaries wrapped in containers,
and they're not small.

Part of the problem is that I don't have CI setup to build/push/deploy from my server,
so I have to do it locally.
I also build both amd64 and arm64 images which doubles the size of the artifacts I push.

Conclusion: setup CI.
