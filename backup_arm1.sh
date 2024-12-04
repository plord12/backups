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
RESTICHOSTNAME=arm1

# backup homeassistant backup archives
#
echo "Backing up /backup"
create_topic /backup
running /backup
${RESTIC} backup --exclude _swap.swap --no-scan --host ${RESTICHOSTNAME} --tag Wokingham /backup 2>/tmp/resticerror && success /backup || failure /backup $(cat /tmp/resticerror)
