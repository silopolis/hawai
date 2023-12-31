#!/bin/bash
# https://www.linuxserver.io/blog/2019-10-01-updating-and-backing-up-docker-containers-with-version-control

set -eux
source .env

# Change variables here:
APPDATA_LOC="/home/user/docker"
COMPOSE_LOC="/home/user/docker-compose.yml"

# Don't change variables below unless you want to customize the script
VERSIONS_LOC="${APPDATA_LOC}/versions.txt"

function update {
    echo "Searching for yq"
    if which yq; then
        echo "yq found, continuing"
    else
        echo "Please install yq first"
        exit 1
    fi
    if [ ! -f "$VERSIONS_LOC" ];then
        for i in $(docker-compose -f "$COMPOSE_LOC" config --services); do
            container_name=$(yq r "$COMPOSE_LOC" services."${i}".container_name)
            image_name=$(docker inspect --format='{{ index .Config.Image }}' "$container_name")
            repo_digest=$(docker inspect --format='{{ index .RepoDigests 0 }}' $(docker inspect --format='{{ .Image }}' "$container_name"))
            echo "$container_name,$image_name,$repo_digest" >> "$VERSIONS_LOC"
        done
    else
        mv "$VERSIONS_LOC" "${VERSIONS_LOC}.bak"
        for i in $(cat "${VERSIONS_LOC}.bak"); do
            container_name=$(echo "$i" | awk -F, '{print $1}')
            image_name=$(echo "$i" | awk -F, '{print $2}')
            repo_digest=$(docker inspect --format='{{ index .RepoDigests 0 }}' $(docker inspect --format='{{ .Image }}' "$container_name"))
            echo "$container_name,$image_name,$repo_digest" >> "$VERSIONS_LOC"
        done
        rm "${VERSIONS_LOC}.bak"
    fi

    # Alternative method that doesn't require yq. Comment out lines 11-34 if you're enabling this method.
    #CONTAINERS=( \
    #    letsencrypt,linuxserver/letsencrypt \
    #    mariadb,linuxserver/mariadb \
    #    phpmyadmin,phpmyadmin/phpmyadmin \
    #    )
    #for i in "${CONTAINERS[@]}"; do
    #    container_name=$(echo "$i" | awk -F, '{print $1}')
    #    image_name=$(echo "$i" | awk -F, '{print $2}')
    #    repo_digest=$(docker inspect --format='{{ index .RepoDigests 0 }}' $(docker inspect --format='{{ .Image }}' "$container_name"))
    #    echo "$container_name,$image_name,$repo_digest" >> "$VERSIONS_LOC"
    #done

    sudo docker-compose -f "$COMPOSE_LOC" pull
    docker-compose -f "$COMPOSE_LOC" down

    APPDATA_NAME=$(echo "$APPDATA_LOC" | awk -F/ '{print $NF}')
    cp -a "$COMPOSE_LOC" "$APPDATA_LOC"/docker-compose.yml.bak
    sudo tar -C "$APPDATA_LOC"/.. -cvzf "$APPDATA_LOC"/../appdatabackup.tar.gz "$APPDATA_NAME"

    docker-compose -f "$COMPOSE_LOC" up -d
    sudo chown "${USER}":"${USER}" "$APPDATA_LOC"/../appdatabackup.tar.gz

    docker image prune -f
}

function restore {
    sudo docker-compose -f "$COMPOSE_LOC" down
    randstr=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-8};echo;)
    mv "$APPDATA_LOC" "${APPDATA_LOC}.$randstr"
    cp -a "$COMPOSE_LOC" "${COMPOSE_LOC}.$randstr"
    mkdir -p "$APPDATA_LOC"
    sudo tar xvf "$APPDATA_LOC"/../appdatabackup.tar.gz -C "$APPDATA_LOC"/../
    for i in $(cat "$VERSIONS_LOC"); do
        image_name=$(echo "$i" | awk -F, '{print $2}')
        repo_digest=$(echo "$i" | awk -F, '{print $3}')
        sed -i "s#image: ${image_name}#image: ${repo_digest}#g" "$COMPOSE_LOC"
    done
    docker-compose -f "$COMPOSE_LOC" pull
    docker-compose -f "$COMPOSE_LOC" up -d
}

function resume {
    for i in $(cat "$VERSIONS_LOC"); do
        image_name="$(echo $i | awk -F, '{print $2}')"
        repo_digest="$(echo $i | awk -F, '{print $3}')"
        sed -i "s#image: ${repo_digest}#image: ${image_name}#g" "$COMPOSE_LOC"
    done
    docker-compose -f "$COMPOSE_LOC" pull
    docker-compose -f "$COMPOSE_LOC" up -d
}

# Check if the function exists
if declare -f "$1" > /dev/null; then
  "$@"
else
  echo "The only valid arguments are update, restore, and resume"
  exit 1
fi