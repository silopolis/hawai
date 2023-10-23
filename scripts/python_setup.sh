#!/bin/bash

set -e #ux

cwd="$(pwd)"
cd "$(dirname "$0")"

if [[ ! $(dpkg -s python3-venv) ]]; then
  echo "-- Install Python venv"
  sudo apt -qq -y install python3-venv;
fi

if [ ! -d .venv ]; then
  echo "-- Create Python '.venv' virtual environment"
  python3 -m venv ../.venv
fi

echo "-- Activate Python '.venv' virtual environment"
source ../.venv/bin/activate
echo "-- Upgrage Python pip and setuptools in venv"
pip install --upgrade setuptools pip
echo "-- Install Python requirements in venv"
pip install -r ../requirements.txt

cd "$cwd"