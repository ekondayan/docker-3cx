#!/bin/bash

# Ownership fix for su/sudo
#chown root:root /bin/su
#chown root:root /usr/bin/sudo
#chown root:root /usr/lib/sudo/sudoers.so
#chown root:root /etc/sudoers
#chown -R root:root /etc/sudoers.d

#chmod +s /usr/bin/sudo

# Make postgres able to access its CFGs
chown -R root:postgres /etc/postgresql
chown -R root:postgres /etc/postgresql-common

# Recreate fresh postgres db, if does not exist yet and fix perms
chown -R postgres:postgres /var/lib/postgresql

DBVER=11
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
