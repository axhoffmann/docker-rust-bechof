#!/bin/bash
# -----------------------------------------------------------------------------
# Script for Updating the dedicated Server of Rust within a docker-Container
#
# Authors: Axel Hoffmann, Matthias Becker
# Updated: Jun 25th, 2015
# -----------------------------------------------------------------------------

# Configuration of the Variables---------------------------------------------------

# Path from rust server
LOGPATH="/var/rust/rustserver"
OLDLOG="/var/rust/rustserver/old_logs"
# Path from the Dockerfile of rust
DOCKFILEPATH="/var/docker/image_src/rust"
# systemctl name
SYSCTL=docker-rust
# Name of docker-Image
NIMG="bechof/rust"
NCON="rust"
# Hostname of the rust Server
HOST=FQDN
# Port from rcon
PORT=28016
# Password for rcon
PASSWORD=Password
# Message for the Players that are currently logged in
MESSAGE1="wird in 5 Minuten neugestartet, da es ein Update gibt. Nach einer kurzen Verzoegerung kann es hier weitergehen!"
MESSAGE2="wird jetzt neugestartet, da es ein Update gibt. Nach einer kurzen Verzoegerung kann es hier weitergehen!"
# Maximum age of the Log-Files in days
MAXAGE=60
DAT=`date +%Y%m%d_%H%M`
# Protocol for sending chat message to Rust by RCON
RCON_PROT='\x11\x00\x00\x00\x01\x00\x00\x00\x03\x00\x00\x00%s\x00\x00\n\x13\x00\x00\x00\x8b\x30\x00\x00\x02\x00\x00\x00\x73\x61\x79\x20%s \x00\x00'
# -----------------------------------------------------------------------------

NV=`egrep "New version" $LOGPATH/Log.Log.txt | wc -l`

if [ $NV -ge 1 ]
    then echo "Update available"
else 
    exit
fi

systemctl status $SYSCTL > /dev/null
P1=$?

if [ $P1 != 0 ]
    then echo "Rust is not running"
else 
     CP=`echo -e "\0\0\0\0TSource Engine Query\0" | nc -u -q 1 $HOST $PORT | tr '[\000-\011\013-\037\177-\377]' '.' | sed 's/\(.*\)\(@.mp\)\([0-9]*\)\(,cp\)\([0-9]*\)\(,\)\(.*\)/\5/'`
    if [ $CP -ge 1 ]
        then
            printf "$RCON_PROT" "$PASSWORD" "$MESSAGE1" | nc -i 1 -q 1 $HOST $PORT
            sleep 10
            printf "$RCON_PROT" "$PASSWORD" "$MESSAGE2" | nc -i 1 -q 1 $HOST $PORT
            sleep 10
    else
        echo "No Player connected"
    fi             
    systemctl stop $SYSCTL
fi

docker rm $NCON
docker rmi $NIMG
cd $DOCKFILEPATH
docker build -t $NIMG .

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

# end of tidy up

docker run -u 556 -d -p=28015:28015/udp -p=28016:28016/udp -p=27015:27015/tcp -p=27015:27015/udp -p=28015:28015/tcp -p=28016:28016/tcp -v=/var/rust:/data --name $NCON "$NIMG:latest"

docker stop $NCON

systemctl start $SYSCTL

systemctl status $SYSCTL > /dev/null
P2=$?

if [ $P2 = 0 ]
    then 
        echo "Update und Start erfolgreich"
else 
    systemctl status $SYSCTL > /dev/null
    P3=$?
    if [ $P3 != 0 ]
        then
            echo "FEHLER!!!"
            exit
    fi
fi

