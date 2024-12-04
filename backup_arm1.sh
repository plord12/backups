#!/bin/bash

# backup for arm1

# bring in common functions
#
cd $(dirname $0)
. ./common.sh

# sets $RESTIC_REPOSITORY and $RESTIC_PASSWORD
#
. ~/.profile

set -e

# this is a low-end server so reduce cpu & skip cache
#
export GOMAXPROCS=1
RESTIC="restic --no-cache"

create_topic /backup
running /backup
${RESTIC} backup --exclude _swap.swap --no-scan --host arm1 --tag Wokingham /backup 2>/tmp/resticerror && success /backup || failure /backup $(cat /tmp/resticerror)
