#!/bin/bash

#set -eux
shopt -s dotglob

source .env

# TODO Rename as 'purge'
# TODO Modularize like bootstrap.sh

echo "-- Uninstall SSL certificate"
vagrant provision proxy1 --provision-with ssl-cert-uninstall

echo "-- Revoke SSL certificate"
vagrant provision proxy1 --provision-with ssl-cert-revoke

echo "-- Destroy Vagrant environment"
vagrant destroy -f
rm -rf .vagrant/*

echo "-- Remove Docker containers"
#docker -D container prune -f
docker rm "$(docker container ls -q)" -f
echo "-- Remove Docker images"
#docker -D image prune -f
docker image rm "$(docker images -aq)" -f
echo "-- Remove Docker networks"
#docker -D network prune -f
docker network rm "$(docker network ls |grep vagrant |cut -d' ' -f1)" -f
echo "-- Purge buildx cache"
docker buildx prune -af

echo "-- Delete data"
sudo rm -rf data/maria1/mysql/*
sudo rm -rf data/wpress1/wordpress/*
sudo find data/ssl/ -type f | sudo xargs rm -vf

echo "-- Purge Python virtual environment"
rm -rf .venv
