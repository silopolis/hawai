#!/bin/bash

set -e #ux
shopt -s dotglob

source .env

echo "-- Uninstall SSL certificate"
vagrant provision proxy1 --provision-with ssl-cert-uninstall

echo "-- Revoke SSL certificate"
vagrant provision proxy1 --provision-with ssl-cert-revoke

echo "-- Destroy Vagrant environment"
vagrant destroy -f
rm -rf .vagrant/*
