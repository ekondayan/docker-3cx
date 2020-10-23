FROM debian:stretch

ARG BUILD_STRING
ARG BUILD_DATE
ARG BUILD_TIME

LABEL build.string $BUILD_STRING
LABEL build.date   $BUILD_DATE
LABEL build.time   $BUILD_TIME

ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.UTF-8
ENV LANGUAGE en
ENV container docker

RUN    apt-get update -y \
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