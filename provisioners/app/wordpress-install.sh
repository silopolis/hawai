#!/bin/bash

set -e #ux

cd /vagrant || exit
source .env

app_host_name="$1"
host_data_dir="$DATA_DIR/$app_host_name"
app_data_dir="$host_data_dir/$APP_SVC_NAME"
app_root_dir="$APPS_ROOT/$APP_SVC_NAME"

if [ ! -d "$host_data_dir" ]; then
  mkdir -p "$host_data_dir"
fi
cd "$host_data_dir"
if [ -z "$(ls -A "$app_root_dir")" ]; then
  echo "-- $APP_NAME not installed."
  if [ ! -f wordpress.tar.gz ]; then
    echo "-- $APP_NAME archive not found. Downloading..."
    wget -q -O "$APP_SVC_NAME.tar.gz" "$APP_ARCH_URL" && \
      echo "-- $APP_NAME archive successfully downloaded."
  fi
  echo "-- Extracting $APP_NAME archive..."
  tar zxf "$APP_SVC_NAME.tar.gz"
  # echo "-- Moving extracted directory to $app_root_dir"
  # mv "$APP_SVC_NAME" "$app_root_dir"
fi

echo "-- Setting up ownership and rights"
chown -R www-data:www-data "$app_root_dir"
chmod -R 755 "$app_root_dir"

if [ "$2" == "--clean" ]; then
  if [ -f wordpress.tar.gz ]; then
    echo "-- Removing $APP_NAME archive"
    rm "$APP_SVC_NAME.tar.gz"
  fi
fi

cd /vagrant
