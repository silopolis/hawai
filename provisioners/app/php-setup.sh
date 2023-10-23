#!/bin/bash

#set -eux
shopt -s dotglob

# shellcheck source=.env
cd /vagrant || exit

# shellcheck source=.env
source .env

cp -vf /etc/php/7.4/fpm/php.ini /etc/php/7.4/fpm/php.ini.dist
cp -vf php.ini /etc/php/7.4/fpm/php.ini
# Configure PHP-FPM to only execute exact matches for files rather than closest
SEARCH=";cgi.fix_pathinfo=.*"
REPLACE="cgi.fix_pathinfo=1"
FILEPATH="/etc/php/7.0/fpm/php.ini"
sudo sed -i "s|$SEARCH|$REPLACE|" $FILEPATH

nginx -s reload
