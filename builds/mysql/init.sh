#!/bin/bash

# 初始化資料庫
mysqld --initialize-insecure

service mysql restart

# 1. 調整本地 root 帳號，設定為空密碼、mysql_native_password 驗證規則
# 2. 創建遠程 root 帳號，設定為空密碼、mysql_native_password 驗證規則
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

CREATE USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;

FLUSH PRIVILEGES;
exit
EOF
