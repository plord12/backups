#!/bin/bash
#
# simple backup test - try restoring one file from each backup
#

# check repo
#
restic check 

rm -rf /tmp/resticrestore
mkdir /tmp/resticrestore

set -e

# Loop through all latest backups
#
for snapshot in $(restic snapshots --latest 1 --json | jq -r '.[] | .short_id' )
do
  file=$(restic ls ${snapshot} | tail -1)
  echo "Restoring ${file} from ${snapshot}"
  restic restore ${snapshot} --include "${file}" --target /tmp/resticrestore
done