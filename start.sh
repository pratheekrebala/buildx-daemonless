#!/bin/sh

args=""
while [ $# -gt 0 ]; do
    case "$1" in
        "--remote-context" )
            remote=$2
            shift 2
            ;;
        *)
            args="${args} $1"
            shift 1
            ;;
    esac
done

set -- ${args}

if [ -n "${remote}" ]; then
    destination=${WORKSPACE:-$(pwd)}
    echo "Downloading context from: ${remote} to ${destination}"
    go-getter "${remote}" ${destination}
fi

buildx.sh $@