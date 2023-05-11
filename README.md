# DNMP
LNMP of Docker Version

## Feature
- ubuntu：20.04
- mysql：latest
    - account：root
    - password：
- nginx：latest
- redis：latest
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

## Basic
1. clone project
    ```sh
    git clone https://github.com/ntut-mika/dnmp.git
    ```

2. start container
    ```sh
    # Windows
    .\start.bat

    # Mac、Linux
    ./start.sh
    ```

3. explain `config.json`
    
    example
    ```json
    {
        // do not change or delete it, the system will maintain automatically
        "ip": "", 

        // modify your value same as example, you need to check your config.json format is same as example while modifying this value
        "config_version": "1.7.0",

        // php cli version inside the container
        "php_cli_version": "8.2",

        // composer version inside the container
        "composer_version": "2", 

        "folders": [
            {
                // whether to use current folders mapping setting
                "enabled": true,

                // which local folder needs to be mapped to the container
                "local": "~/Desktop/projects",

                // where should the local folder be mapped to the container
                "container": "/var/www/projects"
            }
        ],
        "sites": [
            {
                // whether to enable the current website setting
                "enabled": true,

                // site domain
                "domain": "laravel.test",

                // which folder of the container is the project entry point
                "entry_point": "/var/www/projects/demo1/public",

                // which configuration to use in datas/templates/nginx folder
                "nginx_template": "default.conf",

                // which PHP version should this site use
                "php_fpm_version": "8.2",

                // whether to add host mapping
                "auto_host": true,
                
                "cronjobs": [
                    {
                        // whether to enable the current cronjob setting
                        "enabled": true,

                        // job setting
                        "job": "* * * * * cd <entry_point>/../ && php<php_fpm_version> artisan schedule:run > /dev/null 2>&1"
                    }
                ],
                "supervisors": [
                    {
                        // whether to enable the current supervisor setting
                        "enabled": true,

                        // write key=value to supervisor setting
                        "directory": "<entry_point>/../",
                        "command": "php<php_fpm_version> artisan queue:work"
                    }
                ]
            }
        ],
        "ports": [
            {
                // whether to use current port mapping setting
                "enabled": true,

                // which port should be forwarded to the container
                "local": "80",

                // target of local port forwarding
                "container": "80"
            }
        ],
        "xdebug": {
            // whether to enable xdebug
            "enabled": true,

            // some ide need to use this value to listen xdebug, you can modify this value
            "idekey": "phpstorm",

            // which local port should receive xdebug data
            "port": 9003
        }
    }
    ```

4. exit container
    ```sh
    exit
    ```
## Advance
### Change SSL
By default, the system will generate self-signed certificate automatically. If you want to use other certificate, you can put your `ssl.crt` and `ssl.key` into the `datas/ssl/{domain}` folder

### Customize nginx template
Considering that the site settings required by each project are not necessarily the same, if `./datas/templates/nginx/default.conf` does not meet your needs, you can create `./datas/templates/nginx/{name}.conf`, and change the value of `sites.*.template` in `./config.json` to `{name}.conf`

### Configuration php.ini
If you need to change php.ini setting you can change `datas/templates/php/php-cli.ini` and `datas/template/php/php-fpm.ini`

### Use Xdebug
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

## Note
- You don't need to change any file inside src folder
- When you change anything, you need to restart the container to apply the settings
- If you loss your `config.json` you can copy from `src/templates/config/config.json`
