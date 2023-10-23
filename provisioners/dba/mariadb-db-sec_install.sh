#!/bin/bash

#set -eux
shopt -s dotglob

cd /vagrant || exit
source .env

# TODO Enable binding to "127.0.0.1,$DBA_HOST_IP" when upgrading to v10.11+
#DBA_BIND_ADDRESS="${1}"
#DBA_ADMIN_GRANT="$DBA_NET_ADDR/$DBA_NET_MASK"

echo "-- Secure MariaDB default installation"
j2 --format=env templates/dba/dba-mariadb-sec_install.sql.j2 .env \
  | mariadb -sfu root

echo "-- Add database root password to Debian maintenance config"
sudo sed -Ei "s/(password =) .*/\1 $DBA_ROOT_PWD/" /etc/mysql/debian.cnf

echo "-- Make database service available on the network"
# TODO Enable binding to "127.0.0.1,$DBA_HOST_IP" when upgrading to v10.11+
sed -Ei "s/(bind-address *=) .*/\1 ${DBA_BIND_ADDRESS:=0.0.0.0}/" \
  /etc/mysql/mariadb.conf.d/50-server.cnf

echo "-- Enable MariaDB client auto-completion"
sed -Ei "/\[client-mariadb\]/ a auto-rehash" \
  /etc/mysql/mariadb.conf.d/50-client.cnf

echo "-- Use a tmpfs for tmpdir"
mkdir -p /var/lib/mysql/tmp
chown mysql:mysql /var/lib/mysql/tmp
cat <<-EOF >> /etc/fstab
tmpfs   /var/lib/mysql/tmp   tmpfs   rw,gid=mysql,uid=mysql,size=100M,mode=0750,noatime   0 0
EOF
sed -Ei "s|(tmpdir *=) .*|\1 /var/lib/mysql/tmp|" \
  /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl stop mariadb
mount /var/lib/mysql/tmp
systemctl start mariadb

echo "-- Populate time zone tables"
#mariadb-tzinfo-to-sql /usr/share/zoneinfo \
mysql_tzinfo_to_sql /usr/share/zoneinfo \
  | mariadb -u"$DBA_ADM_USER" -p"$DBA_ADM_PWD" mysql
#mariadb-tzinfo-to-sql timezone_file timezone_name \
#  | mariadb -u root -p mysql

# TODO Performance tweaks

systemctl stop mariadb
systemctl start mariadb
