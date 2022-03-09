#!/bin/bash

# 安裝 mysql
apt install -y mysql-server

# 開啟遠程訪問功能
sed -i -e "1,/bind-address/{s/bind-address/#bind-address/}" /etc/mysql/mysql.conf.d/mysqld.cnf 

# 解決啟動時報的 warning
usermod -d /var/lib/mysql/ mysql 

# 將資料庫全部刪除
rm -rf /var/lib/mysql
