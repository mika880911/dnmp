# DNMP
Docker 版 LNMP

## DNMP 集成了哪些東西
- ubuntu 20.04 基礎鏡像
- mysql 最新穩定版
    - 預設帳號：root
    - 預設密碼：無
- nginx 最新穩定版
- reids 最新穩定版
- phpmyadmin 5.1.3 版
- php
    - 5.6 版
    - 7.0 版
    - 7.1 版
    - 7.2 版
    - 7.3 版
    - 7.4 版
    - 8.0 版
    - 8.1 版

## php 額外安裝模組列表
- php-zip
- php-xml 
- php-mysql 
- php-sqlite3
- php-curl
- php-redis
- php-gd

## 使用前請確保符合下列環境需求
- 本機必須先有任一版本 php-cli
- docker

## 使用教學
- 初次使用請先構建 image
    ```bash
    ./buildImage.sh
    ```
- 調整 ./volumes/settings/config.json
    ```json
    {
        # 容器內 php-cli 要使用的版本
        "php-cli-version": "7.4",

        # 容器內 composer 要使用的版本，填1或2
        "composer-version": "2", 

        # 本機目錄映射到容器內部
        "folders": [
            {
                # 本機目錄路徑
                "source": "~/Desktop/project",

                # 容器目錄路徑，該目錄必須為空或不存在
                "dist": "/var/www/project"
            }
        ],

        # 站點配置
        "sites": [
            {
                # 該站點的網域
                "domain": "phpmyadmin.test",

                # 該專案入口文件的所在目錄
                "entry-point": "/builds/phpmyadmin/5.1.3",
                
                # 該站點的要套用的 nginx 模板，模板文件在 volumes/settings/templates/nginx 下
                "template": "default.conf",

                # 選擇該站點的 php-fpm 版本
                "php-fpm-version": "7.4",

                # 是否要將 domain 新增至 /etc/hosts （容器與本機都會添加)
                "auto_host": true,

                # 是否要生成自簽憑證
                "auto_ssl": true
            }
        ],
        
        # 端口映射
        "ports": {
            # 本機端口:容器端口
            "80": "80",
            "443": "443",
            "3306": "3306",
            "6379": "6379"
        }
    }
    ```
    - 啟動並進入容器
        ```bash
        sudo ./start.sh
        ```

## 替換 ssl 憑證
考慮到專案可能需要使用正式憑證而非自簽憑證，在這邊提供替換的具體流程
- step1: 啟動容器
- step2: 將 volumes/settings/config.json 中站點的 auto_ssl 設定為 false
- step3: 將憑證放置 volumes/settings/ssl/{網域名稱}，並命名為 ssl.crt 及 ssl.key，若檔案已存在，請直接覆蓋掉
- step4: 重啟容器

## nginx 模板
考慮到有可能各種專案所需要的站點設定不盡相同，你可以針對特定的專案創建一份專屬的模板，避免每次重啟容器後都需要為站點做微調
- step1: 在 volumes/settings/templates/nginx 下創建一份合法的 nginx 設定檔
- step2: 將 volumes/settings/config.json 中站點的 template 設定成在 volumes/settings/templates/nginx 下的文件名稱
- step3: 重啟容器

## php.ini 修改
- step1: 在 volumes/settings/templates/php 下，有針對 cli 及 fpm 的設定檔，根據需求做調整
- step2: 重啟容器
