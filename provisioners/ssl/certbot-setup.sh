#!/bin/bash

set -e #ux

cd /vagrant || exit
source .env

pxy_host_name="$1"
tmpl_dir="$TMPL_DIR/ssl"

# for d in accounts archive live renewal renewal-hooks; do
#   mkdir -p "/etc/letsencrypt/$d"
# done
# chmod -R 755 "/etc/letsencrypt"

echo '-- Configure certbot DNS authenticator'
j2 --format=env "$tmpl_dir/dns-multi.ini.j2" .env \
  > /etc/letsencrypt/dns-multi.ini;
chmod 600 /etc/letsencrypt/dns-multi.ini

# TODO Switch to systemd timer
echo "-- Setup certificate auto-renewal"
echo "19 14 * * * root python3 -c 'import random; import time; time.sleep(random.random() * 3600)' && sudo certbot renew -q" \
  | sudo tee -a /etc/crontab > /dev/null

# echo "-- Setup certbot auto-update"
# pipx upgrade --include-injected certbot
