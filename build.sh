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

resetDatas() {
    mkdir -p ./datas

    if promptyn "Do you want to reset ssl folder? (y/n)"; then
        rm -rf ./datas/ssl
    fi

    if promptyn "Do you want to reset templates folder? (y/n)"; then
        rm -rf ./datas/templates
        cp -r ./src/templates ./datas/templates
        rm -rf ./datas/templates/config
    fi

    if promptyn "Do you want to reset database? (y/n)"; then
        rm -rf ./datas/database;
    fi

    if promptyn "Do you want to reset config.json? (y/n)"; then
        cp ./src/templates/config/config.json ./config.json
    fi
}


buildImage () {
    docker rmi $1
    docker system prune -af
    docker build -t $1 ./src --no-cache
}

main () {
    resetDatas
    buildImage dnmp
}

main
