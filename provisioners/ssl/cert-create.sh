#!/bin/bash

set -e #ux

cd /vagrant || exit
source .env

pxy_host_name="$1"
ssl_crt_name="${2:-$APP_CRT_NAME}"
ssl_crt_domains="${3:-$APP_CRT_DOMAINS}"
ssl_crt_email="${4:-$APP_CRT_EMAIL}"

echo "-- Request certificate"
certbot certonly --non-interactive --agree-tos --no-eff-email \
  --cert-name "$ssl_crt_name" \
  --domains "$ssl_crt_domains" \
  --email "$ssl_crt_email" \
  --authenticator dns-multi \
  --dns-multi-credentials /etc/letsencrypt/dns-multi.ini
#  --nginx --redirect
