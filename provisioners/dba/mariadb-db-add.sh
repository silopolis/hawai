#!/bin/bash

#set -eux
shopt -s dotglob

cd /vagrant || exit
source .env

DBA_CLIENT_GRANT="$DBA_NET_ADDR/$DBA_NET_MASK"

echo "-- Create '$DBA_DB01_NAME' database"
echo "-- Create DB user: '$DBA_DB01_USER' with passwordd: '$DBA_DB01_PWD'"
echo "-- Grant access from '$DBA_CLIENT_GRANT' to user '$DBA_DB01_USER'"
j2 --format=env templates/dba/dba-mariadb-db-add.sql.j2 .env \
  | mariadb -sfu root -p"$DBA_ROOT_PWD"
