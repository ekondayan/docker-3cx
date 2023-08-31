FROM debian:buster
  
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

#COPY assets/3cx-archive-keyring.gpg /usr/share/keyrings/
COPY assets/3cx_fix_perms.service /lib/systemd/system/
COPY assets/3cx_fix_perms.sh /
COPY assets/3cxpbx.list /etc/apt/sources.list.d/

RUN apt-get update -y \
    &&  apt-get upgrade -y \
    && apt-get install -y --allow-unauthenticated\
         apt-utils \
         wget \
         gnupg2 \
         systemd \
         locales \
    && sed -i 's/\# \(en_US.UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys D34B9BFD90503A6B \
    && sed -i '/^#/ s/^#//' /etc/apt/sources.list.d/3cxpbx.list \
    && apt-get update -y  \
    && apt-get install -y --allow-unauthenticated \
       net-tools \
       dphys-swapfile \
       libcurl3-gnutls \
       libmediainfo0v5 \
       libmms0 \
       libnghttp2-14 \
       librtmp1 \
       libssh2-1 \
       libtinyxml2-6a \
       libzen0v5 \
       $(apt-cache depends 3cxpbx | grep Depends | sed "s/.*ends:\ //" | tr '\n' ' ') \
    && rm -f /lib/systemd/system/multi-user.target.wants/* \
    && rm -f /etc/systemd/system/*.wants/* \
    && rm -f /lib/systemd/system/local-fs.target.wants/* \
    && rm -f /lib/systemd/system/sockets.target.wants/*udev* \
    && rm -f /lib/systemd/system/sockets.target.wants/*initctl* \
    && rm -f /lib/systemd/system/basic.target.wants/* \
    && rm -f /lib/systemd/system/anaconda.target.wants/*

EXPOSE 5015/tcp 5001/tcp 5060/tcp 5060/udp 5061/tcp 5090/tcp 5090/udp 9000-9500/udp 10600-10998/udp

CMD ["/lib/systemd/systemd"]
