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

restic_ver=0.17.3

set -e

curl -L -O https://github.com/restic/restic/releases/download/v${restic_ver}/restic_${restic_ver}_${os}_${arch}.bz2
bunzip2 restic_${restic_ver}_${os}_${arch}.bz2
chmod a+x restic_${restic_ver}_${os}_${arch}
${SUDO} cp restic_${restic_ver}_${os}_${arch} /usr/local/bin/restic
rm restic_${restic_ver}_${os}_${arch} 

curl -L -O https://github.com/restic/rest-server/releases/download/v0.13.0/rest-server_0.13.0_${os}_${arch}.tar.gz
tar -xvzf rest-server_0.13.0_${os}_${arch}.tar.gz
chmod a+x rest-server_0.13.0_${os}_${arch}/rest-server
${SUDO} cp rest-server_0.13.0_${os}_${arch}/rest-server /usr/local/bin/rest-server
rm rest-server_0.13.0_${os}_${arch}.tar.gz
rm -rf rest-server_0.13.0_${os}_${arch}