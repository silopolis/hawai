#!/bin/bash

set -e #ux
shopt -s dotglob

source .env

echo "-- Delete data"
sudo rm -rf "$LOG_DATA_DIR"/*
sudo rm -rf "$DBA_DATA_DIR"/*
sudo rm -rf "$APP_DATA_DIR"/*
sudo find data/ssl/ -type f | sudo xargs rm -vf
sudo find data/ssl/letsencrypt/accounts/acme-v02.api.letsencrypt.org \
        - type d | sudo xargs rmdir -v
