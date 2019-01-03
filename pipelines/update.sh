#!/bin/bash
set -xe

CWD=$(cd $(dirname $0) && pwd)
for pipeline in $CWD/*.py; do
  docker run -i --rm -v "$CWD":/usr/src/meta -w /usr/src/meta -e GO_SERVER_URL=$GO_SERVER_URL dtsato/gomatic /bin/bash -c "python $(basename $pipeline)"
done
