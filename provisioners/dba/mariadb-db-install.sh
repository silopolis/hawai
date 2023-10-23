#!/bin/bash

#set -eux
shopt -s dotglob

cd /vagrant || exit
source .env

systemctl stop mariadb

echo "-- Bootstrap database"
# From https://sources.debian.org/src/mariadb/1%3A10.11.5-3/debian/mariadb-server.postinst/#L185
set +e
#TMPDIR='' bash /usr/bin/mariadb-install-db \
TMPDIR='' bash /usr/bin/mysql_install_db \
  --user=mysql --disable-log-bin \
  --skip-test-db > /dev/null
set -e

systemctl start mariadb
