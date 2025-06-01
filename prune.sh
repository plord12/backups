#!/bin/sh
#
# period prune of the restic repo
#

. ~/.profile

PATH=/usr/local/bin:$PATH
export PATH

# prune
#
sudo -E -u www-data restic --no-cache forget --keep-last 1 --keep-daily 12 --keep-weekly 6 --keep-monthly 6 --keep-yearly 75 --prune > /tmp/prune.out 2>&1 || mosquitto_pub -t homeassistant/infoalert -m "$(uname -n) $0: $(echo ${out} | tail -20)"
cat /tmp/prune.out
