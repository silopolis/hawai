#!/bin/bash

set -eux
shopt -s dotglob

cd /vagrant
source .env

APP_NET_IP="$APP_NET_ROOT.$(($APP_NET_IPMIN + 1))"

echo "-- Configure NGINX proxy"
echo "-- Remove NGINX default configuration"
if [ -f /etc/nginx/sites-enabled/default ]; then
  rm -v /etc/nginx/sites-enabled/default
fi

echo "-- Create NGINX proxy configuration"
cat <<-EOF > /etc/nginx/sites-available/$PXY_SVC_NAME.conf
proxy_http_version 1.1;
proxy_cache_bypass \$http_upgrade;

proxy_set_header Upgrade \$http_upgrade;
proxy_set_header Connection "upgrade";
proxy_set_header Host \$host;
proxy_set_header X-Real-IP \$remote_addr;
proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto \$scheme;
proxy_set_header X-Forwarded-Host \$host;
proxy_set_header X-Forwarded-Port \$server_port;

server {
    listen $LBA_PORT01_GUEST;
    #listen [::]:$LBA_PORT01_GUEST;
    server_name $APP_SVC_FQDN;
    location / {
        proxy_pass "http://$APP_NET_IP/";
    }
}
# server {
#     listen $LBA_PORT02_GUEST;
#     #listen [::]:$LBA_PORT01_GUEST;
#     server_name $APP_SVC_FQDN;
#     location / {
#         proxy_pass "http://$APP_NET_IP/";
#     }
# }
EOF

if [ ! -L /etc/nginx/sites-enabled/$PXY_SVC_NAME.conf ]; then
  ln -s /etc/nginx/sites-available/$PXY_SVC_NAME.conf \
    /etc/nginx/sites-enabled/$PXY_SVC_NAME.conf
fi

echo "-- Restart NGINX to load proxy configuration"
systemctl restart nginx
