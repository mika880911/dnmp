#!/bin/bash

promptyn () {
    while true; do
        read -p "$1 " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please enter Yes or No";;
        esac
    done
}

resetVolumes () {
    rm -rf ./volumes
    mkdir -p ./volumes/settings

    cp ./builds/settings/config.json.example ./volumes/settings/config.json

    mkdir -p ./volumes/settings/templates/php
    cp ./builds/php/templates/php-cli.ini.example ./volumes/settings/templates/php/php-cli.ini
    cp ./builds/php/templates/php-fpm.ini.example ./volumes/settings/templates/php/php-fpm.ini

    mkdir -p  ./volumes/settings/templates/nginx
    cp ./builds/nginx/templates/default.conf.example ./volumes/settings/templates/nginx/default.conf
}

buildImage () {
    docker rmi $1
    docker system prune -af
    docker build -t $1 . --no-cache
}

main () {
    IMAGE_NAME=dnmp

    if promptyn "Do you want to overwrite volumes folder? (y/n)"; then
        resetVolumes
    fi

    buildImage ${IMAGE_NAME}
}

main
