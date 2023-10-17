#!/bin/bash

#set -eux
shopt -s dotglob

cd /vagrant
source .env

DBA_HOST_IP="$DBA_NET_ROOT.$(($DBA_NET_IPMIN + 1))"
APP_ROOT_DIR="/var/www/$APP_SVC_NAME"

# Download and extract $APP_NAME
if [ -z "$(ls -A $APP_ROOT_DIR)" ]; then
  echo "!! $APP_NAME not installed."
  if [ ! -f wordpress.tar.gz ]; then
    echo "II $APP_NAME archive not found. Downloading..."
    wget -q -O $APP_SVC_NAME.tar.gz $APP_ARCH_URL && \
      echo "-- $APP_NAME archive successfully downloaded."
    echo "-- Extracting $APP_NAME archive..."
    tar zxf $APP_SVC_NAME.tar.gz
    echo "-- Moving files to $APP_ROOT_DIR"
    mv $APP_SVC_NAME/* $APP_ROOT_DIR/
    rmdir $APP_SVC_NAME
    echo "-- Removing $APP_NAME archive"
    rm $APP_SVC_NAME.tar.gz
  fi
fi

echo "-- Setting up ownership and rights"
chown -R www-data:www-data $APP_ROOT_DIR
chmod -R 755 $APP_ROOT_DIR

echo "-- Create $APP_NAME config from sample"
if [ -f $APP_ROOT_DIR/wp-config-sample.php ]; then
  cp -f $APP_ROOT_DIR/wp-config-sample.php $APP_ROOT_DIR/wp-config-sample.php.dist
  mv -f $APP_ROOT_DIR/wp-config-sample.php $APP_ROOT_DIR/wp-config.php
fi

echo "-- Configure $APP_NAME database connection"
sed -i "s/'DB_NAME', '.*'/'DB_NAME', '$DBA_DB01_NAME'/" $APP_ROOT_DIR/wp-config.php
sed -i "s/'DB_USER', '.*'/'DB_USER', '$DBA_DB01_USER'/" $APP_ROOT_DIR/wp-config.php
sed -i "s/'DB_PASSWORD', '.*'/'DB_PASSWORD', '$DBA_DB01_PWD'/" $APP_ROOT_DIR/wp-config.php
sed -i "s/'DB_HOST', '.*'/'DB_HOST', '$DBA_HOST_IP'/" $APP_ROOT_DIR/wp-config.php

# Configure PHP
echo "-- Configure PHP"
cp -f /etc/php/7.4/fpm/php.ini /etc/php/7.4/fpm/php.ini.dist
cp -f php.ini /etc/php/7.4/fpm/php.ini
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
cat <<-EOF > /etc/nginx/sites-available/$APP_SVC_NAME.conf
server {
    listen 80;
    root $APP_ROOT_DIR;
    index index.php index.html index.htm;
    server_name $APP_SVC_FQDN;
    client_max_body_size 500M;
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }
    location ~*.(js|css|png|jpg|jpeg|gif|ico)$ {
        expires max;
        log_not_found off;
    }
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    location ~ \.php$ {
         include snippets/fastcgi-php.conf;
         fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
         fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
         include fastcgi_params;
    }
}
EOF

echo "-- Enable $APP_NAME NGINX configuration"
if [ ! -L /etc/nginx/sites-enabled/$APP_SVC_NAME.conf ]; then
  ln -s /etc/nginx/sites-available/$APP_SVC_NAME.conf \
    /etc/nginx/sites-enabled/$APP_SVC_NAME.conf
fi

echo "-- Restart NGINX"
systemctl restart nginx
