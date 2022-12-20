#!/bin/bash

VERSION=18.0.3.450
USER=farfui
HOSTNAME=pbx.yourdomain.com

docker run \
        -d \
        --name 3cx \
        --hostname ${HOSTNAME} \
        --memory 2g \
        --memory-swap 2g \
        --network host \
        --restart unless-stopped \
        -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        -v 3cx_backup:/srv/backup \
        -v 3cx_recordings:/srv/recordings \
        -v 3cx_log:/var/log \
        --cap-add SYS_ADMIN \
        --cap-add NET_ADMIN \
        ${USER}/3cx:${VERSION}
