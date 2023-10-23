#!/bin/bash

#set -eux
shopt -s dotglob

cd /vagrant || exit
source .env
CONF_DIR="$CONF_DIR/app"
# TODO Support HA/Multi-master database
#dba_host_ip="$DBA_NET_ROOT.$((DBA_NET_IPMIN + 1))"
app_root_dir="$APPS_ROOT/$APP_SVC_NAME"

# Download and extract $APP_NAME
# if [ -z "$(ls -A "$app_root_dir")" ]; then
#   echo "!! $APP_NAME not installed."
#   if [ ! -f wordpress.tar.gz ]; then
#     echo "II $APP_NAME archive not found. Downloading..."
#     wget -q -O "$APP_SVC_NAME.tar.gz" "$APP_ARCH_URL" && \
#       echo "-- $APP_NAME archive successfully downloaded."
#     echo "-- Extracting $APP_NAME archive..."
#     tar zxf "$APP_SVC_NAME.tar.gz"
#     echo "-- Moving files to $app_root_dir"
#     mv "$APP_SVC_NAME"/* "$app_root_dir/"
#     rmdir "$APP_SVC_NAME"
#     echo "-- Removing $APP_NAME archive"
#     rm "$APP_SVC_NAME.tar.gz"
#   fi
# fi

# echo "-- Setting up ownership and rights"
# chown -R www-data:www-data "$app_root_dir"
# chmod -R 755 "$app_root_dir"

# echo "-- Create $APP_NAME config from sample"
# if [ -f "$app_root_dir/wp-config-sample.php" ]; then
#   cp -f "$app_root_dir/wp-config-sample.php" "$app_root_dir/wp-config-sample.php.dist"
#   mv -f "$app_root_dir/wp-config-sample.php" "$app_root_dir/wp-config.php"
# fi

# echo "-- Configure $APP_NAME database connection"
# sed -i "s/'DB_NAME', '.*'/'DB_NAME', '$DBA_DB01_NAME'/" "$app_root_dir/wp-config.php"
# sed -i "s/'DB_USER', '.*'/'DB_USER', '$DBA_DB01_USER'/" "$app_root_dir/wp-config.php"
# sed -i "s/'DB_PASSWORD', '.*'/'DB_PASSWORD', '$DBA_DB01_PWD'/" "$app_root_dir/wp-config.php"
# sed -i "s/'DB_HOST', '.*'/'DB_HOST', '$dba_host_ip'/" "$app_root_dir/wp-config.php"

# echo "-- Prevent $APP_NAME HTTPS redirect loop when behind the SSL termination"
# cat <<- EOF >> "$app_root_dir/wp-config.php"
# # Gracefully handle terminated SSL at reverse proxy
# if (strpos(\$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
#     \$_SERVER['HTTPS'] = 'on';
# }

# EOF

# echo "-- Reveal originating IP address to $APP_NAME"
# cat <<- EOF >> "$app_root_dir/wp-config.php"
# if (isset(\$_SERVER['HTTP_X_FORWARDED_FOR'])) 
# {
#     \$forwardedForHeaders = explode( ',', \$_SERVER['HTTP_X_FORWARDED_FOR'] );
#     \$_SERVER['REMOTE_ADDR'] = \$forwardedForHeaders[0];
# }

# EOF

echo "-- Generate $APP_NAME configuration"
j2 --format=env templates/app/wp-config.php.j2 .env \
  > "$app_root_dir/wp-config.php"

echo "-- Configure PHP"
cp -f /etc/php/7.4/fpm/php.ini /etc/php/7.4/fpm/php.ini.dist
cp -f "$CONF_DIR/php.ini" /etc/php/7.4/fpm/php.ini
# Configure PHP-FPM to only execute exact matches for files rather than closest
SEARCH=";cgi.fix_pathinfo=.*"
REPLACE="cgi.fix_pathinfo=1"
FILEPATH="/etc/php/7.4/fpm/php.ini"
sudo sed -i "s|$SEARCH|$REPLACE|" $FILEPATH

if [ ! -d /run/php ]; then
  mkdir /run/php;
fi
systemctl restart php7.4-fpm

# Configure NGINX
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
