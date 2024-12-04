# backups
My backup scripts and documentation

## General priciples

* Use 3-2-1 scheme - at least 3 copys of the data, on 2 media and 1 copy offsite
* Use efficient snapshots - each day backup whats changed
* Keep weekly, monthly and yearly backups
* Use [home assistant](https://www.home-assistant.io/) for status and alerts
* Use cross-platform / open source tools

I mostly use [restic](https://restic.readthedocs.io/en/stable/) with a few additional tools as needed.

## Backup scripts

Each machine I backup has a backup script which uses common functions.  Usually these are started by cron.  For example, on 
server `arm2` I have the crontab -

```
00 01 * * * /home/plord/src/backups/backup_arm2.sh >/home/plord/src/backups/backup_arm2.log 2>&1
```

The script typically includes -

* Use restic to backup to local repository
* Report status to home assistant via MQTT
* Report any errors to home assistant via MQTT

## Local repository

The server `arm4` hosts the local repository on a 4TB SSD drive.  A [rest server](https://github.com/restic/rest-server) is running to allow remote access.

## Offsite repository

The server `arm5` is located offsite and hosts the remote repository on a 4TB SSD drive.  The `copy_remote.sh` script syncronises the two repositories.

## Periodic repository pruning

The script `prune.sh` can be used to periodically remove outdated data to avoid running out of disk space.

## Home assistant

The local home assistant instance displays the status of both repositories -

![home assistant](./homeassistant.png)

The following home assistant rules are of interest -

### Report failures

If a failure message is receieved, call the info script (which logs and alerts via signal) -

```
alias: Restic failure
description: ""
triggers:
  - trigger: mqtt
    topic: homeassistant/sensor/restic/#
conditions:
  - condition: template
    value_template: "{{ trigger.payload is match(\"Failure\") }}"
actions:
  - action: script.info
    metadata: {}
    data:
      message: restic backup reported failure.  Topic:{{ trigger.topic }}
mode: single
```

### Check for old backups

If a backup just isn't happing, we don't get a failure yet the time since the last backup increases.  So this script looks for this case -

```
alias: Test for old backlups
description: If backup is older than 5 days, send an alert
sequence:
  - repeat:
      for_each: >-
        {{ states | selectattr('entity_id', 'match', 'sensor.restic_*') |
        selectattr('attributes.program_version', 'match', 'restic*') |
        map(attribute='entity_id') | list }}
      sequence:
        - if:
            - condition: template
              value_template: >-
                {{ as_timestamp(now())-as_timestamp(state_attr(repeat.item,
                "time")) > 86400*5 }}
          then:
            - action: script.info
              data:
                message: >-
                  Backup "{{ state_attr(repeat.item, "friendly_name") }}" is too
                  old ({{state_attr(repeat.item, "time")}})
  - repeat:
      for_each: >-
        {{ states | selectattr('entity_id', 'match', 'sensor.remote_restic_*') |
        selectattr('attributes.program_version', 'match', 'restic*') |
        map(attribute='entity_id') | list }}
      sequence:
        - if:
            - condition: template
              value_template: >-
                {{ as_timestamp(now())-as_timestamp(state_attr(repeat.item,
                "time")) > 86400*5 }}
          then:
            - action: script.info
              data:
                message: >-
                  Backup "{{ state_attr(repeat.item, "friendly_name") }}" is too
                  old ({{state_attr(repeat.item, "time")}})
```

## Restoring

Restoring of files can be done on the command line or via a GUI such as [resric browser](https://github.com/emuell/restic-browser).

![browser](./browser.png)

Some useful commands are shown below, but also refer to the [restic docs](https://restic.readthedocs.io/en/stable/).

Note that hosts and paths with spaces will have to be quoted.

### List the latest snapshot of each backup

```
$ restic snapshots --latest 1
repository bd3a858e opened (version 2, compression level auto)
ID        Time                 Host                      Tags        Paths                                         Size
------------------------------------------------------------------------------------------------------------------------------
46b19d06  2024-10-10 17:46:08  arm3                      Wokingham   /var/AmazonCopy                               52.620 GiB

636a8b45  2024-11-08 03:39:08  arm3                      Wokingham   /var/google/plord1250-drive                   5.767 GiB

2d664274  2024-12-04 00:04:26  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal           10.731 GiB

9b61d859  2024-12-04 10:21:25  plordmacbook              Wokingham   /Users/plord                                  340.246 GiB
...
```

### List the snapshots of a specific backup

```
$ restic snapshots --host "Peter's Galaxy S20 FE 5G" --path "/storage/emulated/0/Download/Signal "
repository bd3a858e opened (version 2, compression level auto)
ID        Time                 Host                      Tags        Paths                                 Size
---------------------------------------------------------------------------------------------------------------------
06ba14f8  2024-10-18 21:59:41  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.287 GiB
dcc9f70c  2024-10-31 09:06:09  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.368 GiB
44983c0f  2024-11-03 00:04:46  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.374 GiB
91dd9e0b  2024-11-10 00:17:15  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.452 GiB
9585a700  2024-11-16 00:05:14  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.576 GiB
2bd20d6f  2024-11-21 00:33:22  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.664 GiB
c5917a64  2024-11-22 04:04:26  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.673 GiB
4dfa81ac  2024-11-25 08:05:06  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.681 GiB
3f2228df  2024-11-26 00:46:00  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.681 GiB
8e7a4f36  2024-11-27 00:11:34  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.683 GiB
75c31ed6  2024-11-28 05:04:47  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.701 GiB
93cf69a3  2024-11-29 03:04:37  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.720 GiB
9bda2b99  2024-11-30 00:04:14  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.720 GiB
37ef3430  2024-12-01 09:40:03  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.730 GiB
e83a6da0  2024-12-02 00:44:30  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.730 GiB
f180cc32  2024-12-03 09:05:44  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.731 GiB
2d664274  2024-12-04 00:04:26  Peter's Galaxy S20 FE 5G              /storage/emulated/0/Download/Signal   10.731 GiB
---------------------------------------------------------------------------------------------------------------------
17 snapshots
```

### List the contents of a given snapshot

```
$ restic ls 2d664274
repository bd3a858e opened (version 2, compression level auto)
[0:18] 100.00%  83 / 83 index files loaded
snapshot 2d664274 of [/storage/emulated/0/Download/Signal ] at 2024-12-04 00:04:26.27960027 +0000 UTC by @Peter's Galaxy S20 FE 5G filtered by []:
/storage
/storage/emulated
/storage/emulated/0
/storage/emulated/0/Download
/storage/emulated/0/Download/Signal 
/storage/emulated/0/Download/Signal /signal-2024-12-02-00-57-54.backup
/storage/emulated/0/Download/Signal /signal-2024-12-03-00-55-23.backup
```

### Search for a file or directory

```
$ restic find backup_arm2.sh
repository bd3a858e opened (version 2, compression level auto)
[0:03] 100.00%  83 / 83 index files loaded
Found matching entries in snapshot 8736a232 from 2024-12-04 10:43:26
/home/plord/src/backups/backup_arm2.sh

Found matching entries in snapshot df0c33a7 from 2024-12-04 12:05:32
/home/plord/src/backups/backup_arm2.sh

Found matching entries in snapshot e7861b52 from 2024-12-04 12:39:22
/home/plord/src/backups/backup_arm2.sh

Found matching entries in snapshot bb9fa890 from 2024-12-04 15:32:30
/home/plord/src/backups/backup_arm2.sh
```

### Restore a file

```
$ restic restore 2d664274 --include "/storage/emulated/0/Download/Signal /signal-2024-12-02-00-57-54.backup" --target /tmp
repository bd3a858e opened (version 2, compression level auto)
[0:17] 100.00%  83 / 83 index files loaded
restoring snapshot 2d664274 of [/storage/emulated/0/Download/Signal ] at 2024-12-04 00:04:26.27960027 +0000 UTC by @Peter's Galaxy S20 FE 5G to /tmp
Summary: Restored 6 / 1 files/dirs (5.365 GiB / 5.365 GiB) in 5:04

$ find /tmp/storage/
/tmp/storage/
/tmp/storage/emulated
/tmp/storage/emulated/0
/tmp/storage/emulated/0/Download
/tmp/storage/emulated/0/Download/Signal 
/tmp/storage/emulated/0/Download/Signal /signal-2024-12-02-00-57-54.backup
```

### See whats changed between snapshots

```
$ restic diff f180cc32 e83a6da0
repository bd3a858e opened (version 2, compression level auto)
comparing snapshot f180cc32 to e83a6da0:

[0:18] 100.00%  83 / 83 index files loaded
+    /storage/emulated/0/Download/Signal /signal-2024-11-30-00-52-21.backup
+    /storage/emulated/0/Download/Signal /signal-2024-12-01-00-55-14.backup
-    /storage/emulated/0/Download/Signal /signal-2024-12-02-00-57-54.backup
-    /storage/emulated/0/Download/Signal /signal-2024-12-03-00-55-23.backup

Files:           2 new,     2 removed,     0 changed
Dirs:            0 new,     0 removed
Others:          0 new,     0 removed
Data Blobs:   7371 new,  7237 removed
Tree Blobs:      6 new,     6 removed
  Added:   10.731 GiB
  Removed: 10.731 GiB
```

## Other tools used

The backup scripts also make use of -

* [rclone](https://rclone.org/) to copy files from cloud storage (Google Drive and Google Photos) prior to backing up with restic
* [offlineimap](http://www.offlineimap.org) to download email from imap server prior to backing up with restic
* [mosquitto_pub](https://mosquitto.org/man/mosquitto_pub-1.html) to communicate with home assistant

## Testing the backups

The simple script `test-backup.sh` tests the backups by attempting to restore a file from the latest snapshots.