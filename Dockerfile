FROM debian:bullseye-slim as base

RUN apt update && apt install curl -y

RUN mkdir -p /tmp/export/bin

RUN curl -Ls \
  https://github.com/GoogleCloudPlatform/docker-credential-gcr/releases/download/v2.1.6/docker-credential-gcr_linux_amd64-2.1.6.tar.gz \
  | tar -xz -C /tmp/export/bin docker-credential-gcr

RUN curl -Ls \
  https://github.com/docker/buildx/releases/download/v0.10.3/buildx-v0.10.3.linux-amd64 \
  > /tmp/export/bin/buildx \
  && chmod +x /tmp/export/bin/buildx

FROM golang:alpine AS go-getter

RUN apk add --no-cache curl

RUN mkdir /tmp/go-getter && curl -Ls \
  https://github.com/hashicorp/go-getter/archive/refs/tags/v2.2.0.tar.gz \
  | tar -xz -C /tmp/go-getter --strip-components=1 \
  && cd /tmp/go-getter/cmd/go-getter \
  && go install \
  && rm -rf /tmp/go-getter

FROM moby/buildkit:master-rootless as buildkit

COPY --from=base /tmp/export/bin/ /usr/local/bin/
COPY --from=go-getter /go/bin/go-getter /usr/local/bin/

COPY --chmod=0755 buildctl.sh /usr/local/bin/buildctl.sh

ENTRYPOINT ["/usr/local/bin/buildctl.sh"]