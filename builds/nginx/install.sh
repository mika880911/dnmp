#!/bin/bash

# 關閉交互問答安裝 nginx
apt install -y nginx

# 刪除已存在的站點
rm -rf /etc/nginx/sites-available/*
rm -rf /etc/nginx/sites-enabled/*
