FROM ghcr.io/seankhliao/blogengine AS build
WORKDIR /workspace
COPY . .
RUN ["/bin/blogengine", "-src=newtab.md", "-dst=index.html"]

FROM ghcr.io/seankhliao/webserve
COPY --from=build /workspace/index.html /srv/http/index.html
ENTRYPOINT ["/bin/webserve", "-webserve.src=/srv/http"]
