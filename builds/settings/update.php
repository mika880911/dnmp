<?php

class App
{
    protected $configPath = __DIR__ . '/../../settings/config.json';
    protected $phpIniSoruceDir = __DIR__ . '/../../settings/templates/php';
    protected $nginxConfigSoruceDir = __DIR__ . '/../../settings/templates/nginx';
    protected $phpVersions = ['5.6', '7.0', '7.1', '7.2', '7.3', '7.4', '8.0', '8.1'];
    protected $config;

    public function __construct()
    {
        $this->config = json_decode(file_get_contents($this->configPath), true);
    }

    /**
     * 切換 php 版本
     */
    public function switchPhpCliVersion()
    {
        $phpCliVersion = $this->config['php-cli-version'];

        echo "switch php cli to $phpCliVersion...\n\n";

        $this->excuteCommand('rm /etc/alternatives/php');
        $this->excuteCommand("ln /usr/bin/php$phpCliVersion /etc/alternatives/php");
    }

    /**
     * 切換 composer 版本
     */
    public function switchComposerVersion()
    {
        $composerVersion = $this->config['composer-version'];

        echo "switch composer to $composerVersion...\n\n";

        $this->excuteCommand("composer self-update --$composerVersion");
    }

    /**
     * 設定 php.ini
     */
    public function configurationPhp()
    {   
        echo "configuration php...\n\n";
        
        foreach ($this->phpVersions as $phpVersion) {
            $cliIni = file_get_contents($this->phpIniSoruceDir . "/php-cli.ini");
            $fpmIni = file_get_contents($this->phpIniSoruceDir . "/php-fpm.ini");
            file_put_contents("/etc/php/$phpVersion/cli/php.ini", $cliIni);
            file_put_contents("/etc/php/$phpVersion/fpm/php.ini", $fpmIni);
        }
    }
     
    /**
     * 設定站點
     */
    public function configurationNginx()
    {
        echo "configuration nginx ...\n\n";
        $sites = $this->config['sites'];

        foreach ($sites as $site) {
            $template = file_get_contents($this->nginxConfigSoruceDir . '/' . $site['template']);
            foreach ($site as $key => $value) {
                $template = str_replace("<$key>", $site[$key], $template);
            }

            $fileName = $site['domain'];
            file_put_contents("/etc/nginx/sites-enabled/$fileName", $template);
        }
    }

    /**
     * 設定 ssl
     */
    public function configurationSSL()
    {
        echo "configuration ssl...\n\n";
        $sites = $this->config['sites'];

        foreach ($sites as $site) {
            $domain = $site['domain'];
            $this->excuteCommand("mkdir -p '/settings/ssl/$domain'");
            if ($site['auto_ssl']) {
                $command = "openssl req -x509 -new -nodes -sha256 -utf8 -days 3650 -newkey rsa:2048 -keyout '/settings/ssl/$domain/ssl.key' -out '/settings/ssl/$domain/ssl.crt' -config /builds/settings/ssl/ssl.conf";
                $this->excuteCommand($command);
            }
        }
    }

    /**
     * 重啟所有服務
     */
    public function restartAllService()
    {
        echo "start nginx...\n\n";
        # 重啟 nginx
        $this->excuteCommand('service nginx restart');
        
        # 重啟所有 php
        echo "start php-fpm...\n\n";
        foreach ($this->phpVersions as $phpVersion) {
            $this->excuteCommand("service php$phpVersion-fpm restart");
        }
        
        # 檢查 /var/lib/mysql 是否有資料
        if (count(scandir('/var/lib/mysql')) == 2) {
            # 沒資料就初始化資料庫
            echo "initialize and start mysql...\n\n";
            $this->excuteCommand('bash /builds/mysql/init.sh');
        } else {
            echo "start mysql...\n\n";
            $this->excuteCommand('service mysql restart');
        }

        echo "start redis...\n\n";
        $this->excuteCommand('service redis-server start');
    }

    /**
     * 新增容器內 /etc/hosts
     */
    public function configurationHosts()
    {
        $hostContent = file_get_contents('/etc/hosts');

        $sites = $this->config['sites'];
        
        foreach ($sites as $site) {
            $autoHost = $site['auto_host'];
            if ($autoHost) {
                $domain = $site['domain'];
                $record = "127.0.0.1 $domain";
                if (stristr($hostContent, $record) === false) {
                    $hostContent .= "\n127.0.0.1 $domain";
                }
            }
        }

        file_put_contents('/etc/hosts', $hostContent);
    }

    public function excuteCommand($command)
    {
        return shell_exec($command . " > /dev/null 2>/dev/null");
    }

    public function run()
    {
        $this->switchPhpCliVersion();
        $this->switchComposerVersion();
        $this->configurationPhp();
        $this->configurationNginx();
        $this->configurationSSL();
        $this->configurationHosts();
        $this->restartAllService();
    }
}

$app = new App();
$app->run();
