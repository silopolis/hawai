#!/bin/bash

#set -eux
shopt -s dotglob

cd /vagrant
source .env

echo "-- Obtain & install certificate"
certbot --nginx --non-interactive --agree-tos \
  --cert-name "$CRT_NAME" --domains "$CRT_DOMAINS" --email "$CRT_EMAIL" \
  --redirect


echo "-- Restart NGINX and PHP-FPM"
systemctl restart nginx
systemctl restart php7.4-fpm
