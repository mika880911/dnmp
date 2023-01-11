# DNMP
LNMP of Docker Version

## Feature
- ubuntu：20.04
- mysql：lates
    - account：root
    - password：
- nginx：latest
- reids：latest
- php
    - 5.6
    - 7.0
    - 7.1
    - 7.2
    - 7.3
    - 7.4
    - 8.0
    - 8.1
    - 8.2

## Environment Required
- [Docker](https://www.docker.com/)

## Tutorial
1. clone project
    ```sh
    git clone https://github.com/ntut-mika/dnmp.git
    ```
2. start container
    ```sh
    # Windows(PowerShell)
    .\start.ps1

    # Mac、Linux
    ./start.sh
    ```
3. explain `config.json`
    - `ip`: do not change or delete it, the system will automatically maintain

    - `config-version`: modify your value same as example, you needs to check your config.json format is same as example while modifying this value
    
    - `php-cli-version`: php cli version inside the container
    
    - `composer-version`: composer version inside the container
    
    - `folders.*.local`: which local folder needs to be mapped into the container

    - `folders.*.container`: where should the local folder be mapped to the container

    - `sites.*.enabled`: whether to enable the website
    
    - `sites.*.domain`: site domain

    - `sites.*.entry-point`: which folder of the container is the project entry point

    - `sites.*.template`: which configuration to use in ./datas/templates/nginx folder
    
    - `sites.*.php-fpm-version`: which PHP version should this site use
    
    - `sites.*.auto_host`: whether to add host mapping

    - `ports.*.local`: which port should be forwarded to the container

    - `ports.*.container`: target of local port forwarding

    - `xdebug.enabled`: whether to enable xdebug

    - `xdebug.port`: which local port should receive xdebug data

    - `xdebug.idekey` some ide need to use this value to listen xdebug, you can modify this value

    example
    ```json
    {
        "ip": "",
        "config-version": "1.6.0",
        "php-cli-version": "8.2",
        "composer-version": "2", 
        "folders": [
            {
                "local": "~/Desktop/projects",
                "container": "/var/www/projects"
            }
        ],
        "sites": [
            {
                "enabled": true,
                "domain": "laravel.test",
                "entry-point": "/var/www/projects/demo1/public",
                "template": "default.conf",
                "php-fpm-version": "8.2",
                "auto_host": true
            },
            {
                "enabled": true,
                "domain": "wordpress.test",
                "entry-point": "/var/www/projects/demo2",
                "template": "default.conf",
                "php-fpm-version": "8.2",
                "auto_host": true
            }
        ],
        "ports": [
            {
                "local": "80",
                "container": "80"
            },
            {
                "local": "443",
                "container": "443"
            },
            {
                "local": "3306",
                "container": "3306"
            },
            {
                "local": "6379",
                "container": "6379"
            }
        ],
        "xdebug": {
            "enabled": true,
            "idekey": "phpstorm",
            "port": 9003
        }
    }
    ```
4. Change SSL

    By default system automatically generate self-signed certificate, if you want to use other certificate, you can put your `ssl.crt` and `ssl.key` into the `datas/ssl/{domain} folder

5. Customize nginx template
    
    Considering that the site settings required by each project are not necessarily the same, if `./datas/templates/nginx/default.conf` does not meet your needs, you can create `./datas/templates/nginx/{name}.conf`, and change the value of `sites.*.template` in `./config.json` to `{name}.conf`

6. Configuration php.ini

    if you need to change php.ini setting you can change `datas/templates/php/php-cli.ini` and `datas/template/php/php-fpm.ini`
7. Use Xdebug
    - vscode example (.vscode/launch.json)
        ```json
        {
            "version": "0.2.0",
            "configurations": [
                {
                    "name": "Listen for Xdebug",
                    "type": "php",
                    "request": "launch",
                    "port": 9003,
                    "pathMappings": {
                        "/var/www/projects/demo1": "${workspaceFolder}"
                    }
                },
            ]
        }
        ```
8. stop container
    ```sh
    exit
    ```

## Note
- You don't need to change any file inside src folder
- When you change anything, you need to restart the container to apply the settings


## CONTRIBUTING
[link](https://github.com/ntut-mika/dnmp/blob/1.x/.github/CONTRIBUTING.md)

## CODE OF CONDUCT
[link](https://github.com/ntut-mika/dnmp/blob/1.x/.github/CODE_OF_CONDUCT.md)
