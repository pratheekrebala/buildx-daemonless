# Daemonless Buildkit builds using buildx

A small utility docker image that allows using `buildx` commands without an external daemon.

# Usage

### Rootless build

```
docker run -it --rm \
  --security-opt seccomp=unconfined \
  --security-opt apparmor=unconfined \
  -v ./example:/workspace \
  publici/buildx \
  build -push example:latest /workspace
```

### Remote context

The image bundles the `go-getter` package so a remote build context can be provided. This allows for a stateless builder that can e.g. point to S3 buckets, GCS buckets, Git commits etc.

If using a remote context, use a relative path (`./`) to point to subdirs inside a bundle

```
docker run -it --rm \
  --security-opt seccomp=unconfined \
  --security-opt apparmor=unconfined \
  publici/buildx \
  --remote-context https://github.com/docker/getting-started.git
  --push -t test:workspace
  ./getting-started-master
```