#!/bin/bash

set -e #ux

cd /vagrant || exit
source .env

app_host_name="$1"
app_conf_dir="$CONF_DIR/app"
host_data_dir="$DATA_DIR/$app_host_name"
app_data_dir="$host_data_dir/$APP_SVC_NAME"
app_root_dir="$APPS_ROOT/$APP_SVC_NAME"

# TODO Support HA/Multi-master database
#dba_host_ip="$DBA_NET_ROOT.$((DBA_NET_IPMIN + 1))"

echo "-- Generate $APP_NAME configuration"
j2 --format=env templates/app/wp-config.php.j2 .env \
  > "$app_root_dir/wp-config.php"
chown www-data:www-data "$app_root_dir/wp-config.php"
chmod o-rwx "$app_root_dir/wp-config.php"

echo "-- Configure PHP"
cp -f "/etc/php/$APP_PHP_VERSION/fpm/php.ini" \
  "/etc/php/$APP_PHP_VERSION/fpm/php.ini.dist"
cp -f "$app_conf_dir/php.ini" "/etc/php/$APP_PHP_VERSION/fpm/php.ini"
# Configure PHP-FPM to only execute exact matches for files rather than closest
# SEARCH=".*cgi.fix_pathinfo=.*"
# REPLACE="cgi.fix_pathinfo=1"
# FILEPATH="/etc/php/$APP_PHP_VERSION/fpm/php.ini"
# sudo sed -i "s|$SEARCH|$REPLACE|" $FILEPATH

if [ ! -d /run/php ]; then
  mkdir /run/php;
fi

systemctl restart "php$APP_PHP_VERSION-fpm"

# Configure NGINX
# TODO Split NGINX config out
# TODO Review NGINX modules enabled by default
echo "-- Disable useless NGINX modules"
if [ -f /etc/nginx/modules-enabled/50-mod-nchan.conf ]; then
  rm /etc/nginx/modules-enabled/50-mod-nchan.conf
fi

echo "-- Disable NGINX default configuration"
if [ -f /etc/nginx/sites-enabled/default ]; then
  rm /etc/nginx/sites-enabled/default
fi

echo "-- Create $APP_NAME NGINX configuration"
j2 --format=env templates/app/nginx-app.conf.j2 .env \
  > "/etc/nginx/sites-available/$APP_SVC_NAME.conf"

echo "-- Enable $APP_NAME NGINX configuration"
if [ ! -L "/etc/nginx/sites-enabled/$APP_SVC_NAME.conf" ]; then
  ln -s "/etc/nginx/sites-available/$APP_SVC_NAME.conf" \
    "/etc/nginx/sites-enabled/$APP_SVC_NAME.conf"
fi

# Update Htaccess whitelist for reverse proxy setup
# Make sure this block is before any block that performs the normal
# redirection to route everything through index.php, otherwise it
# essentially has no effect.
# cat << EOF >> .Htaccess
# <IfModule mod_rewrite.c>
# RewriteEngine on
# RewriteCond %{REQUEST_URI} ^(.*)?wp-login\.php(.*)$ [OR]
# RewriteCond %{REQUEST_URI} ^(.*)?wp-admin$
# RewriteCond %{HTTP:X-FORWARDED-FOR} !^xxx.xxx.xxx.xxx$
# RewriteCond %{HTTP:X-FORWARDED-FOR} !^yyy.yyy.yyy.yyy$
# RewriteCond %{HTTP:X-FORWARDED-FOR} !^zzz.zzz.zzz.zzz$
# RewriteRule ^(.*)$ - [R=403,L]
# </IfModule>
# EOF


echo "-- Restart NGINX"
systemctl restart nginx

# Loopback Requests Issue
# If site health check reports 'The REST API encountered an error...and : '
# Edit /etc/hosts and make site's domain point to reverse proxy (internal)
# IP address
