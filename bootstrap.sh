#!/bin/bash

#set -eux
shopt -s dotglob

echo "-- Source '.env' configuration file"
source .env

if [ ! $(dpkg -l python3-venv | grep -q "^ii") ]; then
  echo "-- Install Python venv"
  sudo apt -qq -y install python3-venv;
fi
if [ ! -d .venv ]; then
  echo "-- Create Python '.venv' virtual environment"
  python3 -m venv .venv
fi
echo "-- Activate Python '.venv' virtual environment"
source .venv/bin/activate
echo "-- Upgrage Python pip and setuptools"
pip install --upgrade setuptools pip
echo "-- Install Python requirements"
pip install -r requirements.txt

echo "-- Build docker images"
for i in base mariadb nginx lep lemp; do
  echo "-- Build '$i' docker image"
  docker buildx build -t silopolis:$i -f docker/$i.dockerfile .;
done

echo "-- Install Vagrant plugins"
vagrant plugin install vagrant-scp #vagrant-env vagrant-hostmanager

echo "-- Boostrap Vagrant environment"
vagrant up --no-parallel
# vagrant up networks
# vagrant up admin1
# vagrant up maria1 --provision-with install-db
# vagrant up maria1 --provision-with secure-install
# vagrant up maria1 --provision-with database-setup
# vagrant up wpress1
