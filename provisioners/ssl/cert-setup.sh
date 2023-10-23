#!/bin/bash

#set -eux
shopt -s dotglob

cd /vagrant || exit
source .env
TMPL_DIR="$TMPL_DIR/ssl"

echo '-- Configure certbot DNS authenticator'
j2 --format=env "$TMPL_DIR/dns-multi.ini.j2" .env \
  | tee /etc/letsencrypt/dns-multi.ini;

echo "-- Request certificate"
certbot certonly -v --non-interactive --agree-tos --no-eff-email \
  --cert-name "$SSL_CRT_NAME" \
  --domains "$SSL_CRT_DOMAINS" \
  --email "$SSL_CRT_EMAIL" \
  --authenticator dns-multi \
  --dns-multi-credentials /etc/letsencrypt/dns-multi.ini
#  --nginx --redirect

# TODO Switch to systemd timer
echo "-- Setup certificate auto-renewal"
echo "19 14 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && sudo certbot renew -q" \
  | sudo tee -a /etc/crontab > /dev/null

# echo "-- Setup certbot auto-update"
# pipx upgrade --include-injected certbot
