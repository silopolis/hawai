#!/bin/bash

#set -eux
shopt -s dotglob

source .env

for i in base mariadb nginx lep lemp; do
  echo "-- Building '$i' docker image"
  docker buildx build -t silopolis:$i -f $i.dockerfile .;
done

echo "-- Boostraping Vagrant environment"
vagrant up --no-parallel
# vagrant up networks
# vagrant up admin1
# vagrant up maria1 --provision-with install-db
# vagrant up maria1 --provision-with secure-install
# vagrant up maria1 --provision-with database-setup
# vagrant up wpress1