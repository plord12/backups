#!/bin/bash

# backup for arm4

# bring in common functions
#
cd $(dirname $0)
. ./common.sh

# sets $RESTIC_REPOSITORY and $RESTIC_PASSWORD
#
. ~/.profile

set -e

# save installed packages
#
apt list --installed > /home/plord/installed-packages.txt

# run as root and ensure we use common cache
#
RESTIC="sudo -E restic --cache-dir /root/.cache/restic"

# backup home directory
#
echo "Backing up /home"
create_topic /home
running /home
${RESTIC} backup  --tag Wokingham --exclude .cache --exclude .cargo --exclude .gradle --exclude .rustup /home 2>/tmp/resticerror && success /home || failure /home $(cat /tmp/resticerror)

# backup /etc
#
echo "Backing up /etc"
create_topic /etc
running /etc
${RESTIC} backup --tag Wokingham --exclude .cache /etc /usr/local /root /var/spool /opt 2>/tmp/resticerror && success /etc || failure /etc $(cat /tmp/resticerror)
