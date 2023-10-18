#!/bin/bash

set -eux
shopt -s dotglob

cd /vagrant || exit
source .env

APP_NET_IP="$APP_NET_ROOT.$((APP_NET_IPMIN + 1))"

echo "-- Configure NGINX load-balancer"
echo "-- Remove NGINX default configuration"
if [ -f /etc/nginx/sites-enabled/default ]; then
  rm -v /etc/nginx/sites-enabled/default
fi

echo "-- Create NGINX proxy configuration"
cat <<-EOF > "/etc/nginx/sites-available/$LBA_SVC_NAME.conf"
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
proxy_connect_timeout   90;
proxy_send_timeout      90;
proxy_read_timeout      90;
proxy_buffers           32 4k;

client_max_body_size    10m;
client_body_buffer_size 128k;

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

# Redirect HTTP requests to HTTPS
# server {
#     listen 80;
#     server_name $APP_SVC_FQDN;
#
#     location / {
#         return 301 https://$APP_SVC_FQDN\$request_uri;
#     }
# }
# server {
#     listen $LBA_PORT02_GUEST default_server ssl;
#     #listen [::]:$LBA_PORT01_GUEST;
#     server_name $APP_SVC_FQDN;
#
#     ssl on;
#     ssl_certificate      ssl/$APP_SVC_FQDN.crt;
#     ssl_certificate_key  ssl/$APP_SVC_FQDN.key;
#     # TLSv1.3 requires OpenSSL v1.1.1+, check with 'openssl version'
#     ssl_protocols        TLSv1.2 TLSv1.3;
#     ssl_ciphers RC4:HIGH:!aNULL:!MD5;
#     ssl_prefer_server_ciphers on;
#     ssl_session_cache    shared:SSL:10m;
#     ssl_session_timeout  10m;
#
#     keepalive_timeout    60;
#
#     location / {
#         proxy_pass "http://$APP_NET_IP/";
#     }
# }
EOF

if [ ! -L "/etc/nginx/sites-enabled/$LBA_SVC_NAME.conf" ]; then
  ln -s "/etc/nginx/sites-available/$LBA_SVC_NAME.conf" \
    "/etc/nginx/sites-enabled/$LBA_SVC_NAME.conf"
fi

echo "-- Restart NGINX to load proxy configuration"
systemctl restart nginx
