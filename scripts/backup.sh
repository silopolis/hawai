#!/bin/bash


set -e #ux

## Record directory we are called from
cwd="$(pwd)"
## Change to project directory
cd "$(dirname "$0")/.."
# shellcheck source="../.env"
source .env

## Get timestamp
NOW="$(date -u +%Y%m%d%H%M%S%Z)"
## Get containers list by names
CT_NAMES="$(docker container ls -a | awk 'NR>1 {print $NF}')"


function container-snapshot-create {
  ## args: list of container names
  containers=$*
  containers="${containers:=$CT_NAMES}"
  for ct in $containers; do
    ## FIXME Stop before commit ?
    ## Check if container is running
    echo "-- Commit running containers changes to backup images"
    if docker ps | grep -q "$ct"; then
      ct_proj_rep="$PROJECT_CODE/$ct"
      ct_bkp_img="$ct_proj_rep:$NOW"
      echo "-- Commit $ct changes to $ct_bkp_img"
      ## Commit current container state to image
      docker commit --pause "$ct" "$ct_bkp_img"
      #docker tag "$ct_bkp_img" "$ct_proj_rep:snapshot"
    fi
    ## And/or push image to registry
  done
}


function container-snapshot-save {
  ## args: list of container images
  snapshot_images=$*
  snapshot_images_ls="$(docker image ls --all \
    --filter=reference="hawai*/*UTC" \
    --format '{{.Repository}}:{{.Tag}}')"
  snapshot_images="${snapshot_images:=$snapshot_images_ls}"
  echo "-- Create archive(s) of container snapshot image(s)"
  for image in $snapshot_images; do
    snapshot_arch_name="$(echo -n "$image" | sed -e 's|/|-|' -e 's|:|-|').tar"
    if [[ ! -f $BKP_CTNR_DIR/$snapshot_arch_name ]]; then
      ## Save image to archive
      echo "-- Save $image to $snapshot_arch_name"
      docker save --output "$BKP_CTNR_DIR/$snapshot_arch_name" "$image"
    else
      echo "-- Container snapshot archive already exists: $BKP_CTNR_DIR/$snapshot_arch_name"
    fi
  done
}


function container-snapshot-remove {
  ## args: list of container images
  snapshot_images=$*
  snapshot_images_ls="$(docker image ls --all \
    --filter=reference="hawai*/*UTC" \
    --format '{{.Repository}}:{{.Tag}}')"
  snapshot_images="${snapshot_images:=$snapshot_images_ls}"
  echo "-- Remove container(s) snapshot image(s)"
  for image in $snapshot_images; do
    echo "-- Remove $image image"
    docker rmi --force "$image"
  done
}


function container-backup-create {
  ## args: list of container names
  container-snapshot-create "$@"
  container-snapshot-save "$@"
}


## TODO container-snapshot-load: load container snapshot from archive
function container-snapshot-load {
  docker load --input $archive
}


## TODO container-snapshot-push: push container snapshot to repository
function container-snapshot-push {
  docker_repo="$DOCKER_REP_ADDR:$DOCKER_REP_PORT"
  docker login
  docker tag $snapshot_image $docker_repo/$snapshot_image
  docker push $snapshot_image
}


## TODO container-snapshot-pull: pull container snapshot from repository
function container-snapshot-pull {
  docker login
  docker pull my-backup:latest
}


## TODO container-snapshot-restore: restore container snapshot from archive or repository
function container-snapshot-restore {
  container-load
  ## or
  container-pull

  ## Run restored container
  docker run --detach $snapshot
}


## TODO Add capability to archive any image, not only snapshots
function container-archive-create {
  container-container-snapshot-save "$@"
}


function container-archive-delete {
  ## args: list of container archive names
  snapshot_archives=$*
  snapshot_archives_ls="$BKP_CTNR_DIR/*"
  snapshot_archives="${snapshot_archives:=$snapshot_archives_ls}"
  echo "-- Delete container(s) snapshot archive(s)"
  for archive in $snapshot_archives; do
    archive="$(echo -n "${archive##*/}" | sed -e 's|/|-|' -e 's|:|-|')"
    #if [[ ! -f $BKP_CTNR_DIR/$archive ]]; then
      echo "-- Delete $archive archive"
      rm -vf "$BKP_CTNR_DIR/$archive"
    #else
    #  echo "-- Container archive doesn't exist: $BKP_CTNR_DIR/$snapshot_arch_name"
    #fi
  done
}


## TODO Archive Dockerfile with corresponding container (-> smart load function)
# cd <path/to/dockerfile-dir> && \
#   tar -cvf ~/backup/<dockerfile-backup>.tar ./Dockerfile
# cd <path/to/dockerfile-dir> && \
#   tar -xvf ~/backup/<dockerfile-backup>.tar


## ?: Create archive Compose file with corresponding containers
# cd <path/to/docker-compose-dir> && \
#   tar -cvf ~/backup/<compose-backup>.tar .
# cd <path/to/docker-compose-dir> && \
#   tar -xvf ~/backup/<compose-backup>.tar


## Volumes backup are currently done at host level as a first iteration
## and as only bind-mounts are supported ATM
## TODO volume-backup
function volume-backup {
  docker run --rm \
    --volumes-from dckr-site \
    --volume ~/backup:/backup \
    ubuntu \
    bash -c 'cd /var/lib/dckr/content && tar cvf /backup/dckr-site.tar .'
}


## TODO volume-restore
function volume-restore {
  docker volume create dckr-volume-2

  docker run --rm \
    --volumes-from <container-id> \
    --volume ~/backup:/backup \
    ubuntu \
    bash -c "cd <path/to/volume/data> && tar -xvf /backup/<volume-backup>.tar"
}


function data-dump {
  container="$1"
  # MySQL
  docker exec "$container" /usr/bin/mysqldump \
    --user=root \
    --password="$DBA_ROOT_PWD" \
    "$DB_NAME" \
    > "$BKP_DUMP_DIR/$DB_NAME.sql"

  #PostgreSQL
  docker exec "$container" /usr/bin/pg_dump \
    --format="$PG_DUMP_FORMAT" \
    --clean \
    --if-exists \
    --dbname="$DB_NAME" \
    > "$BKP_DUMP_DIR/$DB_NAME.sql"
}


function data-restore {
  cat "$BKP_DUMP_DIR/$DB_NAME.sql" \
    | docker exec --interactive "$container" \
      /usr/bin/mysql --user=root --password="$DBA_ROOT_PWD" "$DB_NAME"

  docker exec --interactive "$container" \
    /usr/bin/pg_restore --dbname="$DB_NAME" < "$BKP_DUMP_DIR/$DB_NAME.sql"
  
  cat "$BKP_DUMP_DIR/$DB_NAME.sql" \
  | docker exec --interactive "$container" \
    /usr/bin/psql --user=root --password="$DBA_ROOT_PWD" "$DB_NAME"
}


COMMAND="$1"
shift
OPTION="$1"
shift
ARGS="$@"
case $COMMAND in
  container) # display Help
    case $OPTION in
      create)
        container-backup-create "$ARGS"
        ;;
      restore)
        container-backup-restore "$ARGS"
        ;;
      remove)
        container-backup-remove "$ARGS"
        ;;
      \?) # Invalid option
        echo "Error: Invalid $COMMAND command option"
        echo "Valid options are create, restore, remove"
        exit 1
        ;;
    esac
    ;;
  snapshot) # display Help
    case $OPTION in
      create)
        container-snapshot-create "$ARGS"
        ;;
      save)
        container-snapshot-save "$ARGS"
        ;;
      remove)
        container-snapshot-remove "$ARGS"
        ;;
      \?) # Invalid option
        echo "Error: Invalid $COMMAND command option"
        echo "Valid options are create, save, remove"
        exit 1
        ;;
    esac
    ;;
  archive) # Enter a name
    case $OPTION in
      create) # display Help
        container-archive-create "$ARGS"
        ;;
      delete) # display Help
        container-archive-delete "$ARGS"
        ;;
      \?) # Invalid option
        echo "Error: Invalid $COMMAND command option"
        echo "Valid options are create, delete"
        exit 1
        ;;
    esac
    ;;
  volume)
    case $OPTION in
      backup)
        volume-backup-create "$ARGS"
        ;;
      restore)
        volume-backup-restore "$ARGS"
        ;;
      remove)
        volume-snapshot-remove "$ARGS"
        ;;
      \?) # Invalid option
        echo "Error: Invalid $COMMAND command option"
        echo "Valid options are backup, restore, remove"
        exit 1
        ;;
    esac
    ;;
  data)
    case $OPTION in
      backup)
        data-backup-create "$ARGS"
        ;;
      restore)
        data-backup-restore "$ARGS"
        ;;
      remove)
        data-snapshot-remove "$ARGS"
        ;;
      \?) # Invalid option
        echo "Error: Invalid $COMMAND command option"
        echo "Valid options are backup, restore, remove"
        exit 1
        ;;
    esac
    ;;
  \?) # Invalid command
    echo "Error: Invalid command."
    echo "Valid commands are container, snapshot, archive, volume, or data"
    exit 1
    ;;
esac

## and go back
cd "$cwd"
