**<u>!!! Important note - </u>** If you run the container on an APPARMOR enabled machine you have to add "--security-opt apparmor=unconfined" to the run command.

**<u>!!! Important note -</u>** If you have enabled docker namespaces, you have to change the permissions of some files and directories within the container. **See the section at the end of the description**

Running the container
------------------------

Create a macvlan network. This is an example and you have to translate this command to map your needs.

docker network create \
    -d macvlan \
    --subnet 192.168.1.0/24 \
    --gateway 192.168.1.1 \
    -o parent=eth0 mv_eth0

2. Run the container

docker run \
    -d \
    --hostname {YOUR HOSTNAME} \
    --memory {MEMORY} \
    --memory-swap {SWAP MEMORY} \
    --ip {IP ADDRESS} \
    --network mv_eth0 \
    --restart unless-stopped \
    -v 3cx_backup:/mnt/backup \
    -v 3cx_recordings:/mnt/recordings \
    -v 3cx_log:/var/log \
    -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    --cap-add SYS_ADMIN \
    --cap-add NET_ADMIN \
    --name 3cx \
    farfui/3cx:18.0.3.450

3. Setup the timezone. You can find the full listing under "/usr/share/zoneinfo/".

docker exec 3cx timedatectl set-timezone {YOUR ZONE INFO}

4. Start 3CX Wizard for initial setup

docker exec -ti 3cx /usr/sbin/3CXWizard --cleanup

build.sh - How this container was build
==============================

```bash
#!/bin/bash

VERSION=18.0.3.450
USER=farfui

docker rmi ${USER}/3cx:${VERSION}

docker build \
 --force-rm \
 --no-cache \
 --build-arg BUILD_STRING="$(date -u)" \
 --build-arg BUILD_DATE="$(date +%d-%m-%Y)" \
 --build-arg BUILD_TIME="$(date +%H:%M:%S)" \
 -t 3cx_stage1 .

docker run \
 -d \
 --privileged \
 --name 3cx_stage1_c 3cx_stage1

docker exec 3cx_stage1_c bash -c \
 " systemctl mask systemd-logind console-getty.service container-getty@.service getty-static.service getty@.service serial-getty@.service getty.target \
 && systemctl enable nginx exim4 postgresql \
 && echo 1 | apt-get -y install 3cxpbx"

docker stop 3cx_stage1_c

docker commit 3cx_stage1_c ${USER}/3cx:${VERSION}

docker push ${USER}/3cx:${VERSION}

docker rm 3cx_stage1_c

docker rmi 3cx_stage1
```

Dockerfile
========

```dockerfile
FROM debian:stretch

ARG BUILD_STRING
ARG BUILD_DATE
ARG BUILD_TIME

LABEL build.string $BUILD_STRING
LABEL build.date $BUILD_DATE
LABEL build.time $BUILD_TIME

ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.UTF-8
ENV LANGUAGE en
ENV container docker

RUN apt-get update -y \
 && apt-get upgrade -y \
 && apt-get install -y --allow-unauthenticated \
 apt-utils \
 wget \
 gnupg2 \
 systemd \
 locales \
 && sed -i 's/\# \(en_US.UTF-8\)/\1/' /etc/locale.gen \
 && locale-gen \
 && wget -O- http://downloads.3cx.com/downloads/3cxpbx/public.key | apt-key add - \  
 && echo "deb http://downloads.3cx.com/downloads/debian stretch main" | tee /etc/apt/sources.list.d/3cxpbx.list \
 && apt-get update -y \
 && apt-get install -y --allow-unauthenticated \
 net-tools \
 $(apt-cache depends 3cxpbx | grep Depends | sed "s/.*ends:\ //" | tr '\n' ' ') \
 && rm -f /lib/systemd/system/multi-user.target.wants/* \
 && rm -f /etc/systemd/system/*.wants/* \
 && rm -f /lib/systemd/system/local-fs.target.wants/* \
 && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
 && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
 && rm -f /lib/systemd/system/basic.target.wants/* \
 && rm -f /lib/systemd/system/anaconda.target.wants/*

EXPOSE 5015/tcp 5001/tcp 5060/tcp 5060/udp 5061/tcp 5090/tcp 5090/udp 9000-9500/udp

CMD ["/lib/systemd/systemd"]
```

# Docker namespaces

- Enter the container:
  
  `docker exec -ti 3cx bash`

- Install the `nano` text editor:
  
  `apt-get install nano`

- Create a systemd service file:
  
  `nano /usr/lib/systemd/user/3cx_fix_perms.service` 
  with the following content:

```ini
[Unit]
Description=Fix 3CX permissions

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/3cx_fix_perms.sh

[Install]
WantedBy=multi-user.target
```

- Enable the service: `systemctl enable 3cx_fix_perms`
- Create an executable bash script file `3cx_fix_perms.sh` under `/`

```bash
#!/bin/bash

# Ownership fix for su/sudo
chown root:root /bin/su
chown root:root /usr/bin/sudo
chown root:root /usr/lib/sudo/sudoers.so
chown root:root /etc/sudoers
chown -R root:root /etc/sudoers.d

chmod +s /usr/bin/sudo

# Make postgres able to access its CFGs
chown -R root:postgres /etc/postgresql
chown -R root:postgres /etc/postgresql-common

# Recreate fresh postgres db, if does not exist yet and fix perms
chown -R postgres:postgres /var/lib/postgresql

DBVER=9.6
DBPATH=/var/lib/postgresql/$DBVER/main
if [ ! -e "$DBPATH" ]; then
    mkdir -p $DBPATH
    chown -R postgres:postgres /var/lib/postgresql
    sudo -u postgres /usr/lib/postgresql/$DBVER/bin/initdb $DBPATH
fi

# Postgres wants to access this private SSL key
chown root:postgres /etc/ssl/private
chown postgres:postgres /etc/ssl/private/ssl-cert-snakeoil.key
chmod g-r /etc/ssl/private/ssl-cert-snakeoil.key
```

*The plan is to move this script into the container, but for now the user has to create it manually*

# Contribution

**Emil Kondayan**
