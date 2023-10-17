#!/bin/bash

#set -eux
shopt -s dotglob

cd /vagrant
source .env

cp -vf /etc/php/7.4/fpm/php.ini /etc/php/7.4/fpm/php.ini.dist
cp -vf /vagrant/php.ini /etc/php/7.4/fpm/php.ini

nginx -s reload
