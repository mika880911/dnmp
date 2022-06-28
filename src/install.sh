#!/bin/bash

function installUtils() {
    apt update
    DEBIAN_FRONTEND="noninteractive" apt install -y vim zip unzip wget git software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt update
}

function installNginx() {
    apt install -y nginx

    # remove exist site config
    rm -rf /etc/nginx/sites-available/*
    rm -rf /etc/nginx/sites-enabled/*
}

function installMysql() {
    apt install -y mysql-server

    # enable remote connect
    sed -i -e "1,/bind-address/{s/bind-address/#bind-address/}" /etc/mysql/mysql.conf.d/mysqld.cnf 

    # fixed warning
    usermod -d /var/lib/mysql/ mysql 

    # delete all database
    rm -rf /var/lib/mysql
}

function installPhp() {
    for version in 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1
    do
        apt install -y php${version} php${version}-fpm
        apt install -y \
        php${version}-zip \
        php${version}-xml \
        php${version}-mysql \
        php${version}-sqlite3 \
        php${version}-curl \
        php${version}-redis \
        php${version}-gd \
        php${version}-imagick \
        php${version}-mbstring \

        # start php-fpm first, if never started call restart will not working
        service php${version}-fpm start
    done
}

function installComposer() {
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    mv composer.phar /usr/bin/composer
}

function installRedis() {
    apt install -y redis-server
}

function cleanup() {
    rm -rf /dnmp
}

function install() {
    installUtils
    installNginx
    installMysql
    installPhp
    installComposer
    installRedis
}

function main() {
    install
}

main
