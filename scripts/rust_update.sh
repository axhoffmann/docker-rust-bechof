#!/bin/bash
# -----------------------------------------------------------------------------
# Script for Updating the dedicated Server of Rust within a docker-Container
#
# Authors: Axel Hoffmann, Matthias Becker
# Updated: Jun 25th, 2015
# -----------------------------------------------------------------------------

# Configuration of the Variables---------------------------------------------------
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
ECHO=`which echo`
NC=`which nc`
TR=`which tr`
SED=`which sed`
SYSTEMCTL=`which systemctl`
DOCKER=`which docker`
FIND=`which find`
CUT=`which cut`
# -----------------------------------------------------------------------------

NV=`$ECHO -e "\0\0\0\0TSource Engine Query\0" | $NC -u -q 1 $VERSION_CHECK_HOST $VERSION_CHECK_PORT | $TR '[\000-\011\013-\037\177-\377]' '.' | $SED 's/\(.*\)\(,cp\)\([0-9]*\)\(,v\)\([0-9]*\)\(.*\)/\5/'`
CV=`$ECHO -e "\0\0\0\0TSource Engine Query\0" | $NC -u -q 1 $HOST $PORT | $TR '[\000-\011\013-\037\177-\377]' '.' | $SED 's/\(.*\)\(,cp\)\([0-9]*\)\(,v\)\([0-9]*\)\(.*\)/\5/'`

$ECHO $NV "new Version" > /var/rust/rust_update_$DAT.log
$ECHO $CV "current Version" >> /var/rust/rust_update_$DAT.log

if [ -z $NV ]
    then exit
fi

if [ -z $CV ]
    then exit
fi

if [ $NV = $CV ]
        then NV=`egrep "New version" $LOGPATH/Log.Log.txt | wc -l`
            if [ $NV -ge 1 ]
               then NV=99999
               else exit
            fi
fi


if [ $NV -gt $CV ]
    then $ECHO "Update available"
    else exit
fi

sleep 3m

#$SYSTEMCTL status $SYSCTL > /dev/null
$SYSTEMCTL status $SYSCTL >> /var/rust/rust_update_$DAT.log
P1=$?

if [ $P1 != 0 ]
    then $ECHO "Rust is not running"
else 
    CP=`$ECHO -e "\0\0\0\0TSource Engine Query\0" | $NC -u -q 1 $HOST $PORT | $TR '[\000-\011\013-\037\177-\377]' '.' | $SED 's/\(.*\)\(@.mp\)\([0-9]*\)\(,cp\)\([0-9]*\)\(,\)\(.*\)/\5/'`
    if [ $CP -ge 1 ]
        then
            printf "$RCON_PROT" "$PASSWORD" "$MESSAGE1" | nc -i 1 -q 1 $HOST $PORT
            sleep 2m
            printf "$RCON_PROT" "$PASSWORD" "$MESSAGE2" | nc -i 1 -q 1 $HOST $PORT
            sleep 10
            $ECHO "benachrichtigung ist raus" >> /var/rust/rust_update_$DAT.log
    else
        $ECHO "No Player connected" >> /var/rust/rust_update_$DAT.log
    fi             
    $SYSTEMCTL stop $SYSCTL >> /var/rust/rust_update_$DAT.log
fi

$DOCKER rm $NCON >> /var/rust/rust_update_$DAT.log
$DOCKER rmi $NIMG >> /var/rust/rust_update_$DAT.log
cd $DOCKFILEPATH
$DOCKER build -t $NIMG . >> /var/rust/rust_update_$DAT.log

# tidy up

if [ ! -d $OLDLOG ]
   then mkdir $OLDLOG
        chmod 755 $OLDLOG
fi

cd $LOGPATH
LOGS=`find . -maxdepth 1 -type f -iname "*.txt" | cut -d "/" -f 2 | sed -r 's/([^\.]*)\.txt.*/\1/'`

for i in $LOGS
    do mv $i".txt" $i"_"$DAT".txt"
       mv $i"_"$DAT".txt" $OLDLOG/
done

find $OLDLOG -name "*.txt" -type f -mtime +$MAXAGE -delete

#end of tidy up

$DOCKER run -u 556 -d -p=28015:28015/udp -p=28016:28016/udp -p=28015:28015/tcp -p=28016:28016/tcp -v=/var/rust:/data --name $NCON "$NIMG:latest" >> /var/rust/rust_update_$DAT.log

$DOCKER stop $NCON >> /var/rust/rust_update_$DAT.log

$SYSTEMCTL start $SYSCTL >> /var/rust/rust_update_$DAT.log

$SYSTEMCTL status $SYSCTL > /dev/null
P2=$?

if [ $P2 = 0 ]
    then 
        echo "Update und Start erfolgreich" >> /var/rust/rust_update_$DAT.log
        sh -c "$MAIL1"
else 
    $SYSTEMCTL status $SYSCTL > /dev/null
    P3=$?
    if [ $P3 != 0 ]
        then
            echo "FEHLER!!!" >> /var/rust/rust_update_$DAT.log
            sh -c "$MAIL2"
            exit
    fi
fi

