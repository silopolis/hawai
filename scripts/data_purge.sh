#!/bin/bash

set -e #ux
shopt -s dotglob

## Record directory we are called from
cwd="$(pwd)"
## Change to project directory
cd "$(dirname "$0")/.."
# shellcheck source="../.env"
source .env

echo "-- Delete data"
sudo rm -rf "$LOG_DATA_DIR"/*
sudo rm -rf "$DBA_DATA_DIR"/*
sudo rm -rf "$APP_DATA_DIR"/*
sudo find data/ssl/ -type f | sudo xargs rm -vf
if [[ -d "data/ssl/letsencrypt/accounts/acme-v02.api.letsencrypt.org" ]]; then
  sudo find data/ssl/letsencrypt/accounts/acme-v02.api.letsencrypt.org/ \
    -type d | sudo xargs rmdir -v
fi

## and go back
cd "$cwd"
