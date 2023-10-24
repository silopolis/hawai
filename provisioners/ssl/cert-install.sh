#!/bin/bash

set -e #ux

cd /vagrant || exit
source .env

pxy_host_name="$1"
ssl_crt_name="${2:-$APP_CRT_NAME}"
ssl_crt_domains="${3:-$APP_CRT_DOMAINS}"
ssl_crt_email="${4:-$APP_CRT_EMAIL}"
ssl_crt_root="$SSL_CRT_ROOT/$ssl_crt_name"

echo "-- Install $ssl_crt_name certificate for $APP_SVC_TYPE service"
if [ ! -d "/etc/nginx/ssl/$ssl_crt_name" ]; then
  mkdir -p "/etc/nginx/ssl/$ssl_crt_name"
fi

cd "/etc/nginx/ssl/$ssl_crt_name"
for f in cert privkey fullchain; do
  if [ ! -L "$f.pem" ]; then
    ln -s "$ssl_crt_root/$f.pem" "$f.pem"
  fi
done

cd /vagrant
