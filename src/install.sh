#!/bin/bash

function installUtils()
{
    apt update
    DEBIAN_FRONTEND="noninteractive" apt install -y vim zip unzip wget curl git software-properties-common
    add-apt-repository -y ppa:ondrej/php
    apt update
    update-ca-certificates
}

function installNginx()
{
    apt install -y nginx

    # remove exist site config
    rm -rf /etc/nginx/sites-available/*
    rm -rf /etc/nginx/sites-enabled/*
}

function installMysql()
{
    apt install -y mysql-server

    # enable remote connect
    sed -i -e "1,/bind-address/{s/bind-address/#bind-address/}" /etc/mysql/mysql.conf.d/mysqld.cnf

    # fixed warning
    usermod -d /var/lib/mysql/ mysql

    # fixed debian user not correct
    cat /dev/null > debian.cnf

    # fixed php5 can't connect
    echo '[mysqld]
    default_authentication_plugin=mysql_native_password' > /etc/mysql/conf.d/costomize.cnf

    # delete all database
    rm -rf /var/lib/mysql
}

function installPhp()
{
    for version in 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2
    do
        apt install -y php${version} php${version}-fpm
        DEBIAN_FRONTEND="noninteractive" apt install -y \
        php${version}-zip \
        php${version}-xml \
        php${version}-mysql \
        php${version}-sqlite3 \
        php${version}-curl \
        php${version}-redis \
        php${version}-gd \
        php${version}-imagick \
        php${version}-mbstring \
        php${version}-xdebug \
        php${version}-intl

        # start php-fpm first, if never started call restart will not working
        service php${version}-fpm start
    done
}

function installPhpUnit()
{
    wget https://phar.phpunit.de/phpunit-4.8.phar -O phpunit4
    wget https://phar.phpunit.de/phpunit-5.7.phar -O phpunit5
    wget https://phar.phpunit.de/phpunit-6.5.phar -O phpunit6
    wget https://phar.phpunit.de/phpunit-7.5.phar -O phpunit7
    wget https://phar.phpunit.de/phpunit-8.5.phar -O phpunit8
    wget https://phar.phpunit.de/phpunit-9.6.phar -O phpunit9
    wget https://phar.phpunit.de/phpunit-10.3.phar -O phpunit10

    for version in 4 5 6 7 8 9 10
    do
        chmod +x phpunit${version}
        mv ./phpunit${version} /usr/bin/
    done
}

function installComposer()
{
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    mv composer.phar /usr/bin/composer
}

function installRedis()
{
    apt install -y redis-server

    # enable remote connect
    sed -i -e "69,/bind 127.0.0.1 ::1/{s/bind 127.0.0.1 ::1/# bind 127.0.0.1 ::1/}" /etc/redis/redis.conf
    sed -i -e "1,/protected-mode yes/{s/protected-mode yes/protected-mode no/}" /etc/redis/redis.conf
}

function installCron()
{
    apt install -y cron
}

function installSupervisor()
{
    apt install -y supervisor
}

function installSsh()
{
    apt install -y openssh-server

    # enable empty root connect
    sed -i -e "1,/#PermitEmptyPasswords no/{s/#PermitEmptyPasswords no/PermitEmptyPasswords yes/}" /etc/ssh/sshd_config
    sed -i -e "1,/#PermitRootLogin prohibit-password/{s/#PermitRootLogin prohibit-password/PermitRootLogin yes/}" /etc/ssh/sshd_config

    # disable print lastlog when login
    sed -i -e "1,/#PrintLastLog yes/{s/#PrintLastLog yes/PrintLastLog no/}" /etc/ssh/sshd_config

    # set root user empty password
    passwd -d root
}

function setupWelcome()
{
    cp /dnmp/src/welcome.sh /etc/update-motd.d/93-welcome
    chmod 755 /etc/update-motd.d/93-welcome
}

function cleanup()
{
    rm -rf /dnmp
}

function install()
{
    installUtils
    installNginx
    installMysql
    installPhp
    installPhpUnit
    installComposer
    installRedis
    installCron
    installSupervisor
    installSsh
    setupWelcome
    cleanup
}

function main()
{
    install
}

main
