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

function installMongoDB()
{
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    apt update
    apt install -y mongodb-org

    # enable remobe connect
    sed -i -e "1,/bindIp: 127.0.0.1/{s/bindIp: 127.0.0.1/bindIp: 0.0.0.0/}" /etc/mongod.conf

    # fixed mongod service not exist
    wget https://raw.githubusercontent.com/mongodb/mongo/r7.0.6/debian/init.d -O /etc/init.d/mongod
    sed -i -e "s/-mongodb/-root/g" /etc/init.d/mongod
    chmod 755 /etc/init.d/mongod
}

function installPhp()
{
    for version in 5.6 7.0 7.1 7.2 7.3 7.4 8.0 8.1 8.2 8.3
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
        php${version}-intl \
        php${version}-mongodb

        # start php-fpm first, if never started call restart will not working
        service php${version}-fpm start
    done
}

function installPhpUnit()
{
    for version in 4 5 6 7 8 9 10 11
    do
        wget https://phar.phpunit.de/phpunit-${version}.phar -O phpunit${version}
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
    installMongoDB
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
