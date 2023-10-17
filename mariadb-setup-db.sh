#!/bin/sh

#set -eux
shopt -s dotglob

cd /vagrant
source .env

DBA_CLIENT_GRANT="$DBA_NET_ADDR/$DBA_NET_MASK"

echo "-- Create '$DBA_DB01_NAME' database"
echo "-- Create DB user: '$DBA_DB01_USER' with passwordd: '$DBA_DB01_PWD'"
echo "-- Grant access from '$DBA_CLIENT_GRANT' to user '$DBA_DB01_USER'"
mariadb -sfu root -p"$DBA_ROOT_PWD" <<-EOS
-- create database
CREATE DATABASE $DBA_DB01_NAME;
-- create database user
CREATE USER "$DBA_DB01_USER"@"$DBA_CLIENT_GRANT" IDENTIFIED BY "$DBA_DB01_PWD";
-- set database user privileges
GRANT ALL PRIVILEGES ON $DBA_DB01_NAME.* TO "$DBA_DB01_USER"@"$DBA_CLIENT_GRANT";
-- apply changes
FLUSH PRIVILEGES;
EOS
