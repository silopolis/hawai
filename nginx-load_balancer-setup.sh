#!/bin/bash

set -eux
shopt -s dotglob

cd /vagrant
source .env

APP_NET_IP="$APP_NET_ROOT.$(($APP_NET_IPMIN + 1))"

echo "-- Configure NGINX load-balancer"
echo "-- Remove NGINX default configuration"
if [ -f /etc/nginx/sites-enabled/default ]; then
  rm -v /etc/nginx/sites-enabled/default
fi

echo "-- Create NGINX proxy configuration"
cat <<-EOF > /etc/nginx/sites-available/$LBA_SVC_NAME.conf
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

upstream backend {
    $LBA_LB_ALG;
    server 192.168.10.11;
    server 192.168.10.12;
}

server {
    listen $LBA_PORT01_GUEST;
    #listen [::]:$LBA_PORT01_GUEST;
    server_name $APP_SVC_FQDN;
    location / {
        proxy_pass "http://backend/";
    }
}

# server {
#     listen $LBA_PORT02_GUEST;
#     #listen [::]:$LBA_PORT01_GUEST;
#     server_name $APP_SVC_FQDN;
# 
#     # Path to SSL/TLS certificate
#     ssl_certificate /etc/letsencrypt/live/domain_name/cert.pem;
#     # Path to the private key
#     ssl_certificate_key /etc/letsencrypt/live/domain_name/privkey.pem;
#     # TLS version used
#     ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
# 
#     location / {
#         proxy_pass "http://backend/";
#     }
# }
EOF

if [ ! -L /etc/nginx/sites-enabled/$LBA_SVC_NAME.conf ]; then
  ln -s /etc/nginx/sites-available/$LBA_SVC_NAME.conf \
    /etc/nginx/sites-enabled/$LBA_SVC_NAME.conf
fi

echo "-- Restart NGINX to load proxy configuration"
systemctl restart nginx
