#!/bin/bash

set -e #ux

cwd="$(pwd)"
cd "$(dirname "$0")"

# TODO Add Vagrant install from upstream repository

echo "-- Install Vagrant plugins"
vagrant plugin install vagrant-scp #vagrant-env vagrant-hostmanager

cd "$cwd"
