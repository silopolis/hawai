#!/bin/bash

set -e #ux
shopt -s dotglob

## Record directory we are called from
cwd="$(pwd)"
## Change to project directory
cd "$(dirname "$0")/.."
# shellcheck source="../.env"
source .env

echo "-- Uninstall SSL certificate"
vagrant provision proxy1 --provision-with ssl-cert-uninstall

echo "-- Revoke SSL certificate"
vagrant provision proxy1 --provision-with ssl-cert-revoke

echo "-- Destroy Vagrant environment"
vagrant destroy -f
rm -rf .vagrant/*

## and go back
cd "$cwd"
