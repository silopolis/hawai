#!/bin/bash

set -e #ux
shopt -s dotglob

source .env

./scipts/purge.sh

./scipts/bootstrap.sh
