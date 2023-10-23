#!/bin/bash

set -e #ux

cwd="$(pwd)"
cd "$(dirname "$0")"

echo "-- Install Vagrant plugins"
vagrant plugin install vagrant-scp #vagrant-env vagrant-hostmanager

cd "$cwd"
