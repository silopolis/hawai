#!/bin/bash

set -e #ux
shopt -s dotglob

source .env

./scipts/data_purge.sh

./scipts/docker_prune.sh

./scipts/data_purge.sh

./scipts/python_purge.sh
