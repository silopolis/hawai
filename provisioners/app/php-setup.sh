#!/bin/bash

set -e #ux

# shellcheck source=.env
cd /vagrant || exit

# shellcheck source=.env
source .env

cp -vf "/etc/php/$APP_PHP_VERSION/fpm/php.ini" \
  "/etc/php/$APP_PHP_VERSION/fpm/php.ini.dist"
cp -vf conf/app/php.ini "/etc/php/$APP_PHP_VERSION/fpm/php.ini"
# Configure PHP-FPM to only execute exact matches for files rather than closest
# SEARCH=".*cgi.fix_pathinfo=.*"
# REPLACE="cgi.fix_pathinfo=1"
# FILEPATH="/etc/php/$APP_PHP_VERSION/fpm/php.ini"
# sudo sed -i "s|$SEARCH|$REPLACE|" "$FILEPATH"

nginx -s reload
