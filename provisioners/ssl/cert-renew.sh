#!/bin/bash

set -e #ux

cd /vagrant || exit
source .env

pxy_host_name="$1"
ssl_crt_name="${2:-$APP_CRT_NAME}"

echo "-- Renew $ssl_crt_name certificate"
certbot renew --non-interactive --cert-name "$ssl_crt_name" \
