#!/bin/bash

set -eux
shopt -s dotglob

cd /vagrant || exit
source .env

# APP_NET_IP="$APP_NET_ROOT.$((APP_NET_IPMIN + 1))"

echo "-- Configure NGINX proxy"
echo "-- Remove NGINX default configuration"
if [ -f /etc/nginx/sites-enabled/default ]; then
  rm -v /etc/nginx/sites-enabled/default
fi

echo "-- Create NGINX proxy configuration"
j2 --format=env "$TMPL_DIR/pxy/nginx.conf.j2" .env \
  > "/etc/nginx/sites-available/$PXY_SVC_NAME.conf"


echo "-- Enable NGINX proxy configuration"
if [ ! -L "/etc/nginx/sites-enabled/$PXY_SVC_NAME.conf" ]; then
  ln -s "/etc/nginx/sites-available/$PXY_SVC_NAME.conf" \
    "/etc/nginx/sites-enabled/$PXY_SVC_NAME.conf"
fi

echo "-- Restart NGINX to load proxy configuration"
systemctl restart nginx
