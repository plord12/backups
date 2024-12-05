#!/bin/bash
#
# copy to offsite backup
#

# start VPN
#
sudo ifup wg0

export GOGC=20

PATH=/usr/local/bin:$PATH
export PATH

# bring in common functions
#
cd $(dirname $0)
. ./common.sh

# sets $RESTIC_REPOSITORY and $RESTIC_PASSWORD
#
. ~/.profile

set -e

# the two repos ... passwords are the same
#
WOK_REPO=/mnt/restic
PLY_REPO=rest:http://192.168.177.1:8000
export RESTIC_FROM_PASSWORD=${RESTIC_PASSWORD}

# run as www-data
#
RESTIC="sudo -E -u www-data restic --no-cache"

# add tag for phone
#
${RESTIC} tag --set Wokingham $(${RESTIC} snapshots --json --host "Peter's Galaxy S20 FE 5G" | jq -r '.[] | "\(.short_id)"')

# Wok -> Ply
#
echo "Wokingham -> Plymouth"
export RESTIC_FROM_REPOSITORY=${WOK_REPO}
export RESTIC_REPOSITORY=${PLY_REPO}
out=$(${RESTIC} --repo ${PLY_REPO} copy --from-repo ${WOK_REPO} $(${RESTIC} --repo ${WOK_REPO} snapshots --latest 1 --tag Wokingham --json | jq -r '.[] | "\(.short_id)"') 2>&1) || mosquitto_pub -t homeassistant/infoalert -m "$(uname -n) $0: $(echo ${out} | tail -20)"
echo ${out}

# Ply -> Wok
#
echo "Plymouth -> Wokingham"
export RESTIC_FROM_REPOSITORY=${PLY_REPO}
export RESTIC_REPOSITORY=${WOK_REPO}
out=$(${RESTIC} --repo ${WOK_REPO} copy --from-repo ${PLY_REPO} $(${RESTIC} --repo ${PLY_REPO} snapshots --latest 1 --tag Plymouth --json | jq -r '.[] | "\(.short_id)"') 2>&1) || mosquitto_pub -t homeassistant/infoalert -m "$(uname -n) $0: $(echo ${out} | tail -20)"
echo ${out}

echo "Plymouth latest"
${RESTIC} --repo ${PLY_REPO} snapshots --latest 1

# update plymouth status
#
${RESTIC} --repo ${PLY_REPO} snapshots --latest 1 --json  | jq -r '.[] | "\(.hostname)|\(.paths[0])"' | while IFS="|" read -r hostname paths 
do 
  if [ "${paths}" = "/var/AmazonCopy" -o "${paths}" = "/var/google/plord1250-drive" ]
  then
    # special case - skip old ones
    mosquitto_pub -r -t "homeassistant/sensor/restic/${id}/config" -m ""
    mosquitto_pub -r -t "homeassistant/sensor/restic/${id}/attributes" -m ""
  else 
    echo "updating status ${hostname} ${paths}"

    RESTICHOSTNAME="${hostname}" RESTIC_REPOSITORY=${PLY_REPO} IDPREFIX=remoterestic success "${paths}"
  fi
done

# update any missing status
#
${RESTIC} snapshots --latest 1 --json --host arm5 --host "Peter's Galaxy S20 FE 5G" | jq -r '.[] | "\(.hostname)|\(.paths[0])"' | while IFS="|" read -r hostname paths 
do 
  echo "updating status ${hostname} ${paths}"

  RESTICHOSTNAME="${hostname}" RESTIC_REPOSITORY=${WOK_REPO} success "${paths}"
done

# stop VPN
#
sudo ifdown wg0
