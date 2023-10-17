#!/bin/bash

#set -eux
shopt -s dotglob

cd /vagrant
source .env

cp -vf /etc/nginx/nginx.conf /etc/nginx/nginx.conf.dist
cp -vf /vagrant/nginx.conf /etc/nginx/nginx.conf

nginx -s reload
