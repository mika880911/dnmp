# DNMP
Docker 版 LNMP

## DNMP 集成列表
- ubuntu：20.04
- mysql：最新穩定版
    - 預設帳號：root
    - 預設密碼：無
- nginx：最新穩定版
- reids：最新穩定版
- php
    - 5.6
    - 7.0
    - 7.1
    - 7.2
    - 7.3
    - 7.4
    - 8.0
    - 8.1

## 環境要求
- 任意版本的 php-cli
- 任意版本的 docker

## 教學
- 第一次使用請透過下列指令構建鏡像 (所有問題請輸入 y)
    - Windows 作業系統
        ```bash
        .\build.bat
        ```
    - Mac 或 Linux 作業系統
        ```bash
        ./build.sh
        ```
- 配置 `./config.json`
    ```json
    {
        # 本機 hosts 文件位置
        "hosts-path": "/etc/hosts",

        # 容器內 php-cli 版本
        "php-cli-version": "7.4",

        # 容器內 composer 版本
        "composer-version": "2", 

        # 目錄映射
        "folders": [
            {
                # 本機目錄
                "source": "~/Desktop/projects",

                # 容器內目錄 (該目錄必須不存在，或為空)
                "dist": "/var/www/projects"
            }
        ],

        # nginx 站點配置
        "sites": [
            {
                # 站點網域
                "domain": "laravel9.test",

                # 站點入口文件 (index.php) 位置 
                "entry-point": "/var/www/projects/laravel9.test/public",
                
                # ./datas/templates/nginx 下的檔案名稱
                "template": "default.conf",

                # 此站點要跑在哪個版本的 php 之下
                "php-fpm-version": "8.1",

                # 是否要自動管理 hosts 文件
                "auto_host": true,
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
    - 透過下列指令啟動並進入容器
        - Windows 作業系統
            ```bash
            .\start.bat
            ```
        - Mac 或 Linux 作業系統
            ```bash
            sudo ./start.sh
            ```

## 替換自簽 SSL 憑證
考慮到你的站點有可能需要使用正式 ssl 憑證，你可以參照以下步驟進行設定
1. 啟動容器
2. 將你的 ssl 憑證命名為 `ssl.crt` 及 `ssl.key` 並替換掉 `datas/ssl/{domain}` 目錄下的 `ssl.crt` 及 `ssl.key`
3. 重啟容器

## 自定義 nginx 模板
考慮到每個專案所需要的 `nginx` 站點設定不一定相同，因此請參照以下步驟，創建屬於自己的 `nginx` 模板

1. 在 `datas/templates/ngnix` 目錄下創建一個 `{名稱}.conf` 檔案
2. 編輯 `config.json` 並將站點中 `template` 值設定成 `{名稱}.conf` 
3. 重啟容器

## 配置 php.ini
若要配置 `php.ini` 請參照以下步驟
1. 編輯 `datas/templates/php` 內的 `php-cli.ini` 及 `php-fpm.ini`
2. 重啟容器

## 配置 Xdebug
1. 默認情況下關閉 Xdebug 避免拖慢網站效能，若需要啟動，請將 `datas/templates/xdebug.ini` 內的註解取消
2. 開啟後 `xdebug` 會將資料推往 `9003` 端口，若想修改此端口，請修改 `datas/templates/xdebug.ini` 中的 `xdebug.client_port` 及 `xdebug.remote_port`
3. dnmp 將會自動維護 `xdebug.client_host` 及 `xdebug.remote_host` 因此你不需要調整上述兩個值
4. 在 `vscode` 使用:
    - 將 `port` 修改成對應的值（`dnmp` 預設是 `9003` 端口)
    - 新增 `pathMappings` 其鍵值為 "`容器內專案位置`":`"${workspaceFolder}`"
    - 範例
        ```json
        {
            "name": "Listen for Xdebug",
            "type": "php",
            "request": "launch",
            "port": 9003,
            "pathMappings": {
                "/var/www/projects/laravel9.test": "${workspaceFolder}"
            }
        }
        ```

## 貢獻指南
[連結](https://github.com/ntut-mika/dnmp/blob/1.x/.github/CONTRIBUTING.md)

## 行為準則
[連結](https://github.com/ntut-mika/dnmp/blob/1.x/.github/CODE_OF_CONDUCT.md)
