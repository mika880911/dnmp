#!/bin/bash

version=$1
apt install -y php${version} php${version}-fpm
apt install -y php${version}-zip php${version}-xml php${version}-mysql php${version}-sqlite3 php${version}-curl php${version}-redis php${version}-gd   

# 這邊要先啟動，因為如果沒有先啟動過，就直接調用 restart 會失敗
service php${version}-fpm start
