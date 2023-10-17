#!/bin/bash

#set -eux
shopt -s dotglob

source .env

vagrant destroy -f
sudo rm -vrf data/maria1/mysql/*
sudo rm -vrf data/wpress1/wordpress/*
docker -D container prune -f
docker -D image prune -f
docker -D network prune -f
