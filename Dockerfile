# -----------------------------------------------------------------------------
# docker-rust-bechof
#
# Builds an advanced docker image that can run a Rust dedicated Server
# (http://playrust.com/).
#
# Authors: Axel Hoffmann, Matthias Becker
# Updated: Feb 12th, 2015
# Require: Docker (http://www.docker.io/)
# -----------------------------------------------------------------------------

# Base system is Debian 8 (Jessie)
FROM   debian:8

# The glory team
MAINTAINER Axel Hoffmann, Matthias Becker

# Make sure that everything is running as root
USER   root

# Create folder for Rust
RUN    mkdir /opt/rust

# Adding rust config file and start script
ADD    ./scripts/start /start

# Execute permissions for start script
RUN    chmod +x /start

# Make sure we don't get notifications we can't answer during building.
ENV    DEBIAN_FRONTEND noninteractive

# Variable for steamcmd download path
ENV    STEAMCMD_URL http://media.steampowered.com/installer/steamcmd_linux.tar.gz

# Update packet repository,  upgrade packages and installs requirements
RUN    echo "deb http://ppa.launchpad.net/ubuntu-wine/ppa/ubuntu trusty  main" > /etc/apt/sources.list.d/wine.list
RUN    dpkg --add-architecture i386
RUN    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5A9A06AEF9CB8DB0
RUN    apt-get -y update; apt-get -y upgrade
RUN    apt-get install -y --no-install-recommends wine1.7-amd64 lib32gcc1 xvfb xauth libdbus-1-3

# Create empty skel
RUN    mkdir /etc/skel_empty

# Create steamcmd User
RUN    groupadd -r -g 556 rust && useradd -u 556 -r -g rust -d /data -k /etc/skel_empty -m -s /sbin/nologin rust 

# Download steamcmd and unpack it to /opt/steamcmd
RUN    mkdir /opt/steamcmd
ADD    ${STEAMCMD_URL} /opt/steamcmd/
RUN    cd /opt/steamcmd && tar -xzf steamcmd*.tar.gz && rm *.tar.gz

# Expose ports for rust
#EXPOSE 80
EXPOSE 27015/udp
EXPOSE 27015/tcp
EXPOSE 28015/tcp
EXPOSE 28015/udp
EXPOSE 28016/tcp
EXPOSE 28016/udp

# Download and install rust dedicated server
RUN    /opt/steamcmd/steamcmd.sh +@sSteamCmdForcePlatformType windows +login anonymous +force_install_dir /opt/rust +app_update 258550 -beta experimental validate +quit #

# Delete all the crap
RUN    rm -rf /opt/steamcmd

# Symlink the server dir to the persistent /data directory
RUN    ln -s /data /opt/rust/server

# Switch to steamcmd user, because steamcmd and rust should run as non-root
USER rust
VOLUME ["/data"]

ENTRYPOINT ["/start"]
