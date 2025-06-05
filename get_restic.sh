#!/bin/sh
#
# get restic & test-server binary for this platform

if [ "${USER}" = "root" ]
then
	SUDO=
else
	SUDO="sudo -E"
fi

arch=$(uname -m)
os=$(uname -s | tr 'A-Z' 'a-z')
if [ "${arch}" = "aarch64" ]
then
    arch=arm64
fi

restic_ver=0.18.0
restserver_ver=0.14.0

set -e

curl -L -O https://github.com/restic/restic/releases/download/v${restic_ver}/restic_${restic_ver}_${os}_${arch}.bz2
bunzip2 restic_${restic_ver}_${os}_${arch}.bz2
chmod a+x restic_${restic_ver}_${os}_${arch}
if [ "$(uname -n)" = "core-ssh" ]
then
	${SUDO} cp restic_${restic_ver}_${os}_${arch} restic
else
	${SUDO} cp restic_${restic_ver}_${os}_${arch} /usr/local/bin/restic
fi
rm restic_${restic_ver}_${os}_${arch} 

curl -L -O https://github.com/restic/rest-server/releases/download/v${restserver_ver}/rest-server_${restserver_ver}_${os}_${arch}.tar.gz
tar -xvzf rest-server_${restserver_ver}_${os}_${arch}.tar.gz
chmod a+x rest-server_${restserver_ver}_${os}_${arch}/rest-server
${SUDO} cp rest-server_${restserver_ver}_${os}_${arch}/rest-server /usr/local/bin/rest-server
rm rest-server_${restserver_ver}_${os}_${arch}.tar.gz
rm -rf rest-server_${restserver_ver}_${os}_${arch}