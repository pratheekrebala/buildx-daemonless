#!/bin/sh
# buildctl-daemonless.sh spawns ephemeral buildkitd for executing buildctl.
#
# Usage: buildctl-daemonless.sh build ...
#
# Flags for buildkitd can be specified as $BUILDKITD_FLAGS .
#
# The script is compatible with BusyBox shell.
set -eu

: ${BUILDKITD=buildkitd}
: ${BUILDKITD_FLAGS=}
: ${ROOTLESSKIT=rootlesskit}
: ${XDG_RUNTIME_DIR=/run/user/$(id -u)}
# $tmp holds the following files:
# * pid
# * addr
# * log
tmp=$(mktemp -d /tmp/buildctl-daemonless.XXXXXX)
trap cleanup EXIT

cleanup() {
    echo "Cleaning up..."
    kill $(cat $tmp/pid) || true
    wait $(cat $tmp/pid) || true
    rm -rf $tmp
    &>/dev/null buildx rm remote || true
}

startBuildkitd() {
    sleep 10
    addr=
    helper=
    if [ $(id -u) = 0 ]; then
        addr=unix:///run/buildkit/buildkitd.sock
    else
        addr=unix:///run/user/$(id -u)/buildkit/buildkitd.sock
        helper=$ROOTLESSKIT
        BUILDKITD_FLAGS="$BUILDKITD_FLAGS --oci-worker-no-process-sandbox"
    fi

    $helper $BUILDKITD $BUILDKITD_FLAGS --addr=$addr >$tmp/log 2>&1 &

    pid=$!
    echo $pid >$tmp/pid
    echo $addr >$tmp/addr
}

setupBuildx() {
  buildx inspect remote && buildx rm remote || true
  buildx create --name remote --driver remote $(cat $tmp/addr)
  buildx use remote
  buildx inspect remote --bootstrap
}

startBuildkitd &
setupBuildx &>/dev/null

buildx "$@"