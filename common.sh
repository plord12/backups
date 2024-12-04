#!/bin/bash

# common utility functions for backups
#
# MQTT username / password is set in ~/.config/mosquitto_pub
#

# allow to be overrridden - eg run as root or set cache options
#
RESTIC=restic

# delete MQTT topic - only used when we got things wrong
#
delete_topic() {
	id="restic_$(echo "${1}" | tr " '.-/" "_")$(echo "${2}" | tr " '.-/" "_" | sed -e 's+_$++')"
	mosquitto_pub -r -t "homeassistant/sensor/${id}/config" -m ""
	mosquitto_pub -r -t "homeassistant/sensor/${id}/state" -m ""
	mosquitto_pub -r -t "homeassistant/sensor/${id}/attrinutes" -m ""
}

# create a MQTT topic to report backup status to
#
create_topic() {
	id="restic_$(hostname | tr " '.-/" "_")$(echo "${1}" | tr " '.-/" "_" | sed -e 's+_$++')"
	mosquitto_pub -r -t "homeassistant/sensor/restic/${id}/config" \
		-m "{ \"name\": \"restic $(hostname) ${1} backup status\", \"unique_id\": \"${id}\", \"state_topic\": \"homeassistant/sensor/restic/${id}/state\", \"value_template\": \"{{ value }}\", \"json_attributes_topic\": \"homeassistant/sensor/restic/${id}/attributes\"}"
}

# report backup is running
#
running() {
	id="restic_$(hostname | tr " '.-/" "_")$(echo "${1}" | tr " '.-/" "_" | sed -e 's+_$++')"
	mosquitto_pub -r -t "homeassistant/sensor/restic/${id}/state" -m "Running"
}

# report backup is a success
#
success() {
	id="restic_$(hostname | tr " '.-/" "_")$(echo "${1}" | tr " '.-/" "_" | sed -e 's+_$++')"
	mosquitto_pub -r -t "homeassistant/sensor/restic/${id}/state" -m "Success"
	short_id=$(${RESTIC} snapshots --host $(hostname) --path "${1}" --latest 1 --json | jq -r '.[0].short_id')
	mosquitto_pub -r -t "homeassistant/sensor/restic/${id}/attributes" \
		-m "$(${RESTIC} snapshots ${short_id} --json | jq -c 'add')"
}

# report backup was a failure
#
failure() {
	id="restic_$(hostname | tr " '.-/" "_")$(echo "${1}" | tr " '.-/" "_" | sed -e 's+_$++')"
	shift
	mosquitto_pub -r -t "homeassistant/sensor/restic/${id}/state" -m "Failure $*"
}