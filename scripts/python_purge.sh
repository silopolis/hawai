#!/bin/bash

set -e #ux
shopt -s dotglob

source .env

echo "-- Purge Python virtual environment"
rm -rf .venv
