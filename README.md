# docker-rust-bechof
Builds an advanced docker image that can run a Rust dedicated Server under Linux with Wine.

*Info:* The default port of Rust is `28015` and the RCON port is `28016`.
        The Log- and Config-Path is /var/rust/rustserver/.

## Preparations on the docker host

For this container an empty skel template and the user and group rust with uid and gid 556 is required

**Create empty skel**
```
mkdir /etc/skel_empty
```

**Create user**
```
groupadd -r -g 556 rust && useradd -u 556 -r -g rust -d /data -k /etc/skel_empty -m -s /sbin/nologin rust
```

## Create and run docker container

**To create the docker image execute**
```
docker build -t bechof/rust .
```

**Running the docker container is done by**
```
docker run -u 556 -d -p=28015:28015/udp -p=28016:28016/udp -p=27015:27015/tcp -p=27015:27015/udp -p=28015:28015/tcp -p=28016:28016/tcp -v=/var/rust:/data --name "rust" bechof/rust:latest
```

## Miscellaneous

Now there is an autoupdate-script for updating the server.
The Script checks the Log.Log.txt if an update is available. Than it checks the systemctl-status of rust if it's running or not.
In the next task there is a check of possible online players. If there is someone they will get two text messages in chat, that there are
maintenance and in a few minutes they can continue playing.
Old docker container and images gets deleted, old logs gets moved to old_logs-Folder, than the build-process starts and rust is starting again.

Add the rust_update.sh script in the crontab like you want. Recommended is a start every full hour.

Before starting the script it must be prepared in this sections:

```
# Path from rust server
LOGPATH=/var/rust/rustserver
OLDLOG=/var/rust/rustserver/old_logs
# Path from the Dockerfile of rust
DOCKFILEPATH=/var/docker/image_src/rust
# systemctl name
SYSCTL=docker-rust
# Name of docker-Image
NIMG=bechof/rust
NCON=rust
# Server which uses the most current version of Rust
VERSION_CHECK_HOST=50.22.109.226
VERSION_CHECK_PORT=28016
# Hostname of the own rust Server
HOST=IPorFQDN
# Port from rcon
PORT=28016
# Password for rcon
PASSWORD=password
# Message for the Players that are currently logged in
MESSAGE1="wird in 2 Minuten neugestartet, da es ein Update gibt. Nach einer kurzen Verzoegerung kann es hier weitergehen!"
MESSAGE2="wird jetzt neugestartet, da es ein Update gibt. Nach einer kurzen Verzoegerung kann es hier weitergehen!"
# Maximum age of the Log-Files in days
MAXAGE=60
DAT=`date +%Y%m%d_%H%M`
# Protocol for sending chat message to Rust by RCON
RCON_PROT='\x11\x00\x00\x00\x01\x00\x00\x00\x03\x00\x00\x00%s\x00\x00\n\x13\x00\x00\x00\x8b\x30\x00\x00\x02\x00\x00\x00\x73\x61\x79\x20%s \x00\x00'
MAIL1='{ sleep 2; echo "ehlo rustserver.de"; sleep 2; echo "MAIL FROM: rust@rustserver.de"; sleep 2; echo "RCPT TO: mail@address.com"; sleep 2; echo "DATA"; sleep 2; echo "From: Rust Server on rustserver.de <rust@rustserver.de>"; echo "To: Name <mail@address.com>"; echo "Date: $(date -R)"; echo "SUBJECT: Rust Update"; echo ""; echo "Rust wurde geupdated"; echo "."; echo "QUIT"; } | telnet mailserver.com 25 > /dev/null 2>&1'
MAIL2='{ sleep 2; echo "ehlo rustserver.de"; sleep 2; echo "MAIL FROM: rust@rustserver.de"; sleep 2; echo "RCPT TO: mail@address.com"; sleep 2; echo "DATA"; sleep 2; echo "From: Rust Server on rustserver.de <rust@rustserver.de>"; echo "To: Name <mail@address.com>"; echo "Date: $(date -R)"; echo "SUBJECT: Rust Update"; echo ""; echo "Rust wurde NICHT geupdated"; echo "."; echo "QUIT"; } | telnet mailserver.com 25 > /dev/null 2>&1'
```

Note:
In the ingame chat from Rust there will be wrote "SERVER" before the MESSAGE1 and 2 will appear.
MAIL1 and MAIL2 must be updated with your correct mail data.