#!/bin/bash

# backup for arm3

# bring in common functions
#
cd $(dirname $0)
. ./common.sh

# sets $RESTIC_REPOSITORY and $RESTIC_PASSWORD
#
. ~/.profile

set -e

# run as root and ensure we use common cache
#
RESTIC="sudo -E restic --cache-dir /root/.cache/restic"

# run offlineimap in the backgroup
#
#(
#	set +e
#	killall offlineimap
#	/usr/bin/offlineimap -o >/tmp/offlineimap.log 2>&1
#	if [ $? != 0 ]
#	then
#		(echo "offlineimap"; echo; tail -5 /tmp/offlineimap.log) | signal-cli -u +441189627101 send +447867970260 --message-from-stdin
#	fi 
#)&

# run u3acommunities rsync in background
#
(
	rsync -avz --delete-after u3acommunities.org@ssh.gb.stackcp.com:public_html/wp-content/updraft/ /var/u3acommunities/ >/tmp/rsync.log 2>&1
	if [ $? != 0 ]
	then
		(echo "u3acommunities"; echo; tail -5 /tmp/rsync.log) | signal-cli -u +441189627101 send +447867970260 --message-from-stdin
	fi 
)&

# save installed packages
#
apt list --installed > /home/plord/installed-packages.txt

# backup home directory
#
echo "Backing up /home"
create_topic /home
running /home
${RESTIC} backup  --tag Wokingham --exclude /home/plord/src/immich \
	--exclude .cache \
	--exclude .cargo \
	--exclude .gradle \
	--exclude .rustup \
	--exclude /home/plord/src/docker-mailserver \
	/home 2>/tmp/resticerror && success /home || failure /home $(cat /tmp/resticerror)

# backup /etc
#
echo "Backing up /etc"
create_topic /etc
running /etc
${RESTIC} backup --tag Wokingham --exclude .cache /etc /usr/local /root /var/spool /opt 2>/tmp/resticerror && success /etc || failure /etc $(cat /tmp/resticerror)

# backup webserver
#
echo "Backing up /var/www"
create_topic /var/www
echo .dump | sqlite3 /var/www/html/baikal/Specific/db/db.sqlite | sudo tee /var/www/html/baikal/Specific/db/mydb.sql >/dev/null
running /var/www
${RESTIC} backup --tag Wokingham /var/www 2>/tmp/resticerror && success /var/www || failure /var/www $(cat /tmp/resticerror)

# backup updraft
#
echo "Backing up /var/www/html/public_html/wp-content/updraft"
create_topic /var/www/html/public_html/wp-content/updraft
running /var/www/html/public_html/wp-content/updraft
${RESTIC} backup --tag Wokingham /var/www/html/public_html/wp-content/updraft 2>/tmp/resticerror && success /var/www/html/public_html/wp-content/updraft || failure /var/www/html/public_html/wp-content/updraft $(cat /tmp/resticerror)

# backup immich
#
echo "Backing up immich"
create_topic /home/plord/src/immich
running /home/plord/src/immich
${RESTIC} backup --tag Wokingham --exclude /home/plord/src/immich/postgres --exclude /home/plord/src/immich/library/encoded-video --exclude /home/plord/src/immich/library/thumbs /home/plord/src/immich 2>/tmp/resticerror && success /home/plord/src/immich || failure /home/plord/src/immich $(cat /tmp/resticerror)

# google drive backups
#
# plord1200@gmail.com - padi, first aid, jean & george (moved to immich)
# plord1300@gmail.com - festivals (deleted)
# plord1250@gmail.com - backups (no longer used)
# plord1260@gmail.com - flutter
# plord1270@gmail.com - signal backups (not used)

for user in plord12 
do
	echo "Backing up /var/google/${user}-photos/media/all"
	mkdir -p /var/google/${user}-photos/media/all
	rclone sync google-photos-${user}:/media/all/ /var/google/${user}-photos/media/all/
	create_topic /var/google/${user}-photos/media/all
	running /var/google/${user}-photos/media/all
	( ${RESTIC} backup --tag Wokingham --ignore-inode /var/google/${user}-photos/media/all 2>/tmp/restic-${user}-photos-error && success /var/google/${user}-photos/media/all || failure /var/google/${user}-photos/media/all $(cat /tmp/restic-${user}-photos-error) ) &
done
wait
for user in plord12 plord1260 peterdawn
do
	echo "Backing up /var/google/${user}-drive"
	mkdir -p /var/google/${user}-drive
	rclone sync google-drive-${user}:/ /var/google/${user}-drive/
	create_topic /var/google/${user}-drive
	running /var/google/${user}-drive
	( ${RESTIC} backup --tag Wokingham --ignore-inode /var/google/${user}-drive && success /var/google/${user}-drive 2>/tmp/restic-${user}-drive-error || failure /var/google/${user}-drive $(cat /tmp/restic-${user}-drive-error) ) &
done
wait

#echo "Backing up imap"
#create_topic /var/ImapCopy
#running /var/ImapCopy
#${RESTIC} backup --tag Wokingham /var/ImapCopy /var/ImapCopySaved 2>/tmp/restic-imapcopy-error && success /var/ImapCopy || failure /var/ImapCopy $(cat /tmp/restic-impacopy-error)

echo "Backing up mailserver"
create_topic /home/plord/src/docker-mailserver
running /home/plord/src/docker-mailserver
${RESTIC} backup --tag Wokingham /home/plord/src/docker-mailserver 2>/tmp/restic-imapcopy-error && success /home/plord/src/docker-mailserver || failure /home/plord/src/docker-mailserver $(cat /tmp/restic-impacopy-error)

# arm1 - arm1 isn't really suitable for restic
echo "Backing up arm1 backup"
rclone sync ssh-arm1:/backup/ /var/arm1/backup/
export RESTICHOSTNAME=arm1
create_topic /var/arm1/backup
running /var/arm1/backup
${RESTIC} backup --exclude _swap.swap --tag Wokingham --host ${RESTICHOSTNAME} /var/arm1/backup 2>/tmp/resticerror && success /var/arm1/backup || failure /var/arm1/backup $(cat /tmp/resticerror)

echo "Backing up u3acommunities"
export RESTICHOSTNAME=u3acommunities
create_topic /var/u3acommunities
running /var/u3acommunities
${RESTIC} backup --tag Wokingham --host ${RESTICHOSTNAME} /var/u3acommunities 2>/tmp/restic-u3acommunities-error && success /var/u3acommunities || failure /var/u3acommunities $(cat /tmp/restic-u3acommunities-error)

