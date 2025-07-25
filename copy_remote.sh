#!/bin/bash
#
# copy to offsite backup
#

# stop VPN
#
function stopvpn() {
	echo "Stopping VPN"
	sudo ifdown wg0
	exit
}

trap stopvpn EXIT

set -x

# start VPN
#
echo "Starting VPN"
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
RESTIC="sudo -E -u www-data restic --no-cache --retry-lock 5m"

# Wok -> Ply
#
echo "Wokingham -> Plymouth"
export RESTIC_FROM_REPOSITORY=${WOK_REPO}
export RESTIC_REPOSITORY=${PLY_REPO}
${RESTIC} --repo ${PLY_REPO} copy --from-repo ${WOK_REPO} --tag Wokingham --tag Seascale 2>/tmp/resticcopy.log || mosquitto_pub -t homeassistant/infoalert -m "$(uname -n) $0: $(cat /tmp/resticcopy.log)"
cat /tmp/resticcopy.log

# Ply -> Wok
#
echo "Plymouth -> Wokingham"
export RESTIC_FROM_REPOSITORY=${PLY_REPO}
export RESTIC_REPOSITORY=${WOK_REPO}
${RESTIC} --repo ${WOK_REPO} copy --from-repo ${PLY_REPO} --tag Plymouth 2>/tmp/resticcopy.log || mosquitto_pub -t homeassistant/infoalert -m "$(uname -n) $0: $(cat /tmp/resticcopy.log)"
cat /tmp/resticcopy.log

echo "Plymouth latest"
${RESTIC} --repo ${PLY_REPO} snapshots --latest 1
echo "Wokingham latest"
${RESTIC} --repo ${WOK_REPO} snapshots --latest 1

# update workingham status
#
${RESTIC} --repo ${WOK_REPO} snapshots --latest 1 --json  | jq -r '.[] | "\(.hostname)|\(.paths[0])|\(.tags)"' | while IFS="|" read -r hostname paths tags
do
  case "${tags}" in
  *Keep*) echo "removing wokingham homeassistant status ${hostname} ${paths}"
          RESTICHOSTNAME="${hostname}" RESTIC_REPOSITORY=${WOK_REPO} delete_topic "${paths}"
  	  ;;
  *)      echo "updating wokingham homeassistant status ${hostname} ${paths}"
          RESTICHOSTNAME="${hostname}" RESTIC_REPOSITORY=${WOK_REPO} create_topic "${paths}"
	  ;;
  esac
done

# update plymouth status
#
${RESTIC} --repo ${PLY_REPO} snapshots --latest 1 --json  | jq -r '.[] | "\(.hostname)|\(.paths[0])|\(.tags)"' | while IFS="|" read -r hostname paths tags
do
  case "${tags}" in
  *Keep*) echo "removing plymouth homeassistant status ${hostname} ${paths}"
          RESTICHOSTNAME="${hostname}" RESTIC_REPOSITORY=${PLY_REPO} IDPREFIX=remote_restic delete_topic "${paths}"
  	  ;;
  *)      echo "updating plymouth homeassistant status ${hostname} ${paths}"
          RESTICHOSTNAME="${hostname}" RESTIC_REPOSITORY=${PLY_REPO}  IDPREFIX=remote_restic create_topic "${paths}"
          RESTICHOSTNAME="${hostname}" RESTIC_REPOSITORY=${PLY_REPO} IDPREFIX=remote_restic success "${paths}"
	  ;;
  esac
done

# special case - update any missing status
#
${RESTIC} snapshots --latest 1 --json --host arm5 | jq -r '.[] | "\(.hostname)|\(.paths[0])"' | while IFS="|" read -r hostname paths 
do 
  echo "updating missing status ${hostname} ${paths}"

  RESTICHOSTNAME="${hostname}" RESTIC_REPOSITORY=${WOK_REPO} create_topic "${paths}"
  RESTICHOSTNAME="${hostname}" RESTIC_REPOSITORY=${WOK_REPO} success "${paths}"
done

