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
