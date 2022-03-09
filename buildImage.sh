#!/bin/bash

imageName=dnmp

docker system prune
docker build -t ${imageName} . --no-cache

mkdir -p ./volumes/settings
cp ./builds/settings/config.json.example ./volumes/settings/config.json

mkdir -p ./volumes/settings/templates/php
cp ./builds/php/templates/php-cli.ini.example ./volumes/settings/templates/php/php-cli.ini
cp ./builds/php/templates/php-fpm.ini.example ./volumes/settings/templates/php/php-fpm.ini

mkdir -p  ./volumes/settings/templates/nginx
cp ./builds/nginx/templates/default.conf.example ./volumes/settings/templates/nginx/default.conf
