#!/bin/bash

#set -eux
shopt -s dotglob

source .env

echo "-- Destroy Vagrant environment"
vagrant destroy -f
rm -rf .vagrant/*

echo "-- Prune docker environment"
docker -D container prune -f
docker -D image prune -f
docker -D network prune -f

echo "-- Delete data"
sudo rm -rf data/maria1/mysql/*
sudo rm -rf data/wpress1/wordpress/*

# echo "-- Purge Python virtual environment"
# deactivate
# rm -rf .venv
