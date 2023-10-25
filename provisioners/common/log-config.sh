#!/bin/bash

set -e #ux

cd /vagrant
source .env

log_host_name="$1"
log_host_ip="$2"
tmpl_dir="$TMPL_DIR/log"

# TODO Create common log provisionner
# TODO Configure logging on all guests

if [[ "$log_host_name" == "log"* ]]; then
  # Configure log host
  j2 --format=env "$tmpl_dir/rsyslog-server.conf.j2" .env \
    > /etc/rsyslog.conf
    #| tee /etc/rsyslog.conf
  j2 --format=env "$tmpl_dir/rsyslog-00-receive.conf.j2" .env \
    > /etc/rsyslog.d/00-receive.conf
    #| tee /etc/rsyslog.conf
  j2 --format=env "$tmpl_dir/rsyslog-99-localhost.conf.j2" .env \
    > /etc/rsyslog.d/99-localhost.conf
    #| tee /etc/rsyslog.conf
else
  # Configure log client/sender
  j2 --format=env "$tmpl_dir/rsyslog-client.conf.j2" .env \
    > /etc/rsyslog.conf
  j2 --format=env "$tmpl_dir/rsyslog-00-forward.conf.j2" .env \
    > /etc/rsyslog.d/00-forward.conf
fi

systemctl restart rsyslog
