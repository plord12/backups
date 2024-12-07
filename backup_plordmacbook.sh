#!/bin/bash

# backup for plordmacbook
#
# assumes  the macbook is wokenup for the backups - use :
# 	sudo pmset  repeat wake MTWRFSU 23:59:55

# avoid sleeping whilst this is running
#
sudo pmset sleep 0

# bring in common functions
#
cd $(dirname $0)
. ./common.sh

# sets $RESTIC_REPOSITORY and $RESTIC_PASSWORD
#
. ~/.profile

set -e

PATH=/usr/local/bin:/opt/homebrew/bin:$PATH
export PATH

# run as root and ensure we use common cache
#
RESTIC="sudo -E restic --cache-dir /var/root/restic-cache"

# backup home directory
#
echo "Backing up /Users/plord"
create_topic /Users/plord
running /Users/plord
${RESTIC} backup --tag Wokingham /Users/plord --exclude /Users/plord/Library/CloudStorage --exclude '/Users/plord/Calibre Library/' --exclude '/Users/plord/Library/Caches' 2>/tmp/resticerror && success /Users/plord || failure /Users/plord $(cat /tmp/resticerror)

# backup ebooks seperatly
#
echo "Backing up /Users/plord/Calibre Library"
create_topic '/Users/plord/Calibre Library'
running '/Users/plord/Calibre Library'
${RESTIC} backup --tag Wokingham '/Users/plord/Calibre Library' 2>/tmp/resticerror && success '/Users/plord/Calibre Library' || failure '/Users/plord/Calibre Library' $(cat /tmp/resticerror)

# sync ebooks to webserver, although not currently used
#
echo "Rsyncing /Users/plord/Calibre Library"
rsync --rsync-path 'sudo -E -u calibre rsync' -avz --delete '/Users/plord/Calibre Library/' arm3.local:/var/CalibreLibrary/

# sleep after 1mins
#
sudo pmset sleep 1