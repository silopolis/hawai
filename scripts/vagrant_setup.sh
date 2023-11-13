#!/bin/bash

set -e #ux

## Record directory we are called from
cwd="$(pwd)"
## Change to project directory
cd "$(dirname "$0")/.."
# shellcheck source="../.env"
source .env

# TODO Add Vagrant install from upstream repository

echo "-- Install Vagrant plugins"
vagrant plugin install vagrant-scp #vagrant-env vagrant-hostmanager

## and go back
cd "$cwd"
