#!/bin/bash

apt update
DEBIAN_FRONTEND="noninteractive" apt install -y vim zip unzip wget git software-properties-common
add-apt-repository -y ppa:ondrej/php
apt update

wget http://curl.haxx.se/ca/cacert.pem
mv cacert.pem /usr/lib/ssl/cert.pem
