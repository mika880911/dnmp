<?php

class SetupContainer
{
    protected $config;

    protected $baseDir = __DIR__ . '/..';

    public function __construct()
    {
        $this->config = json_decode(file_get_contents($this->baseDir . '/config.json'), true);
    }

    public function setup()
    {
        $this->setupPhp();
        $this->setupComposer();
        $this->setupNginx();
        $this->setupSSL();
        $this->setupHosts();
        $this->restartService();
    }

    public function setupPhp()
    {
        # setup php-cli version
        $phpCliVersion = $this->config['php-cli-version'];
        echo "setup php to $phpCliVersion...\n\n";
        $this->excuteCommand('rm /etc/alternatives/php');
        $this->excuteCommand("ln /usr/bin/php$phpCliVersion /etc/alternatives/php");

        # setup php.ini
        foreach (['5.6', '7.0', '7.1', '7.2', '7.3', '7.4', '8.0', '8.1'] as $phpVersion) {
            $cliIni = file_get_contents($this->baseDir . '/datas/templates/php/php-cli.ini');
            $fpmIni = file_get_contents($this->baseDir . '/datas/templates/php/php-fpm.ini');

            file_put_contents("/etc/php/$phpVersion/cli/php.ini", $cliIni);
            file_put_contents("/etc/php/$phpVersion/fpm/php.ini", $fpmIni);
        }
    }

    public function setupComposer()
    {
        $composerVersion = $this->config['composer-version'];
        echo "setup composer to $composerVersion...\n\n";
        $this->excuteCommand("composer self-update --$composerVersion");
    }

    public function setupNginx()
    {
        echo "setup nginx ...\n\n";

        foreach ($this->config['sites'] as $site) {
            $fileName = $site['domain'];
            $template = file_get_contents($this->baseDir . '/datas/templates/nginx/' . $site['template']);
            foreach ($site as $key => $value) {
                $template = str_replace("<$key>", $site[$key], $template);
            }

            file_put_contents("/etc/nginx/sites-enabled/$fileName", $template);
        }
    }

    public function setupSSL()
    {
        echo "setup ssl...\n\n";

        foreach ($this->config['sites'] as $site) {
            $domain = $site['domain'];
            $dir = $this->baseDir . '/datas/ssl/' . $domain;
            $this->excuteCommand("mkdir -p '$dir'");

            $sslCrtPath = $dir . '/ssl.crt';
            $sslKeyPath = $dir . '/ssl.key';

            if (file_exists($sslCrtPath) && file_exists($sslKeyPath)) {
                $expiredAt = openssl_x509_parse(file_get_contents($sslCrtPath))['validTo_time_t'];
                if ($expiredAt > time() + 60 * 60 * 24 * 30) {
                    continue;
                }
            }

            $command = "openssl req -x509 -new -nodes -sha256 -utf8 -days 365 -newkey rsa:2048 -keyout '${sslKeyPath}' -out '${sslCrtPath}' -config " . $this->baseDir . '/src/ssl.conf';
            $this->excuteCommand($command);
        }
    }

    public function setupHosts()
    {
        echo "setup /etc/hosts...\n\n";

        $hosts = file_get_contents('/etc/hosts');

        foreach ($this->config['sites'] as $site) {
            if ($site['auto_host']) {
                $domain = $site['domain'];

                if (count(preg_grep("/^(127.0.0.1)([\s\\t]*)($domain)$/", explode("\n", $hosts))) == 0) {
                    $hosts .= "\n127.0.0.1 $domain";
                }
            }
        }

        file_put_contents('/etc/hosts', $hosts);
    }

    public function restartService()
    {
        echo "start nginx...\n\n";
        $this->excuteCommand('service nginx restart');

        echo "start php-fpm...\n\n";
        foreach (['5.6', '7.0', '7.1', '7.2', '7.3', '7.4', '8.0', '8.1'] as $phpVersion) {
            $this->excuteCommand("service php$phpVersion-fpm restart");
        }

        if (count(scandir('/var/lib/mysql')) == 2) {
            echo "initialize and start mysql...\n\n";
            $this->excuteCommand('bash ' . $this->baseDir . '/src/initializeMysql.sh');
        } else {
            echo "start mysql...\n\n";
            $this->excuteCommand('service mysql restart');
        }

        echo "start redis...\n\n";
        $this->excuteCommand('service redis-server start');
    }

    private function excuteCommand($command)
    {
        return shell_exec($command . " > /dev/null 2>/dev/null");
    }
}

$setUpContainer = new SetupContainer();
$setUpContainer->setup();
