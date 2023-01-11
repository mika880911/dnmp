<?php

class SetupContainer
{
    # color
    protected $ERROR_COLOR        = "\033[0;31m";
    protected $SUCCESSFUL_COLOR   = "\033[0;32m";
    protected $DEFAULT_COLOR      = "\033[0m";
    protected $INFO_COLOR         = "\033[0;33m";

    protected $config;

    protected $baseDir = __DIR__ . '/..';

    public function __construct()
    {
        $this->config = json_decode(file_get_contents($this->baseDir . '/config.json'), true);
    }

    public function pipeLine()
    {
        echo "{$this->INFO_COLOR}======= Setup Container Env =======\n{$this->DEFAULT_COLOR}";
        $this->setupPhp();
        $this->setupComposer();
        $this->setupSSL();
        $this->setupHosts();
        $this->setupNginx();
        $this->setupMysql();
        $this->setupRedis();
    }

    public function setupPhp()
    {
        # setup php-cli version
        $phpCliVersion = $this->config['php_cli_version'];
        $this->excuteCommand('rm /etc/alternatives/php');
        $this->excuteCommand("ln -s /usr/bin/php$phpCliVersion /etc/alternatives/php");

        $cliIni       = file_get_contents($this->baseDir . '/datas/templates/php/php-cli.ini');
        $fpmIni       = file_get_contents($this->baseDir . '/datas/templates/php/php-fpm.ini');
        $xdebugIni    = '';

        if ($this->config['xdebug']['enabled']) {
            $xdebugIni  = "zend_extension=xdebug.so\n";
            # xdebug 2
            $xdebugIni .= "xdebug.remote_enable=1\n";
            $xdebugIni .= "xdebug.remote_autostart=1\n";
            $xdebugIni .= "xdebug.remote_port={$this->config['xdebug']['port']}\n";
            $xdebugIni .= "xdebug.remote_host={$this->config['ip']}\n";

            # xdebug 3
            $xdebugIni .= "xdebug.mode=develop,coverage,debug,profile\n";
            $xdebugIni .= "xdebug.start_with_request=yes\n";
            $xdebugIni .= "xdebug.client_port={$this->config['xdebug']['port']}\n";
            $xdebugIni .= "xdebug.client_host={$this->config['ip']}\n";

            $xdebugIni .= "xdebug.idekey={$this->config['xdebug']['idekey']}";
        }

        # setup php.ini
        foreach (['5.6', '7.0', '7.1', '7.2', '7.3', '7.4', '8.0', '8.1', '8.2'] as $phpVersion) {
            file_put_contents("/etc/php/$phpVersion/cli/php.ini", $cliIni);
            file_put_contents("/etc/php/$phpVersion/fpm/php.ini", $fpmIni);
            file_put_contents("/etc/php/$phpVersion/mods-available/xdebug.ini", $xdebugIni);
        }

        foreach ($this->getUsedPhpFpmVersions() as $phpVersion) {
            $this->excuteCommand("service php$phpVersion-fpm restart");
        }

        echo "{$this->SUCCESSFUL_COLOR}php($phpCliVersion)\t(successful)\n{$this->DEFAULT_COLOR}";
    }

    public function setupComposer()
    {
        $composerVersion = $this->config['composer_version'];
        $this->excuteCommand("composer self-update --$composerVersion");

        echo "{$this->SUCCESSFUL_COLOR}composer($composerVersion)\t(successful)\n{$this->DEFAULT_COLOR}";
        $this->excuteCommand('echo export PATH=\"\$HOME/.config/composer/vendor/bin:\$PATH\" >> ~/.bashrc', false);
    }

    public function setupSSL()
    {
        $caCrtPath = $this->baseDir . '/src/DnmpCa.crt';
        $caKeyPath = $this->baseDir . '/src/DnmpCa.key';
        $caSrlPath = $this->baseDir . '/src/DnmpCa.srl';

        copy($caCrtPath, '/usr/local/share/ca-certificates/DnmpCa.crt');

        foreach ($this->config['sites'] as $site) {
            $domain   = $site['domain'];
            $dir      = $this->baseDir . '/datas/ssl/' . $domain;
            $this->excuteCommand("mkdir -p '$dir'");

            $sslCrtPath = $dir . '/ssl.crt';
            $sslKeyPath = $dir . '/ssl.key';
            $sslCsrPath = $dir . '/ssl.csr';

            if (file_exists($sslCrtPath) && file_exists($sslKeyPath)) {
                $expiredAt = openssl_x509_parse(file_get_contents($sslCrtPath))['validTo_time_t'];

                # renew the certificate if it expires after 30 days
                if ($expiredAt > time() + 60 * 60 * 24 * 30) {
                    continue;
                }
            }

            # generate ssl.key
            $command = "openssl genrsa -out \"{$sslKeyPath}\" 4096";
            $this->excuteCommand($command);

            # generate ssl.csr
            $command = "openssl req -key \"{$sslKeyPath}\" -out \"{$sslCsrPath}\" -subj \"/CN={$domain}\" -new -sha256";
            $this->excuteCommand($command);

            # generate ssl.crt
            $command = "bash -c 'openssl x509 -req -sha256 -days 365 -in \"{$sslCsrPath}\" -out \"{$sslCrtPath}\" -CA \"{$caCrtPath}\" -CAkey \"{$caKeyPath}\" -extfile <(printf \"subjectAltName=DNS:{$domain},IP:127.0.0.1\\nextendedKeyUsage = serverAuth\") -CAcreateserial'";
            $this->excuteCommand($command);

            # remove ssl.csr
            $command = "rm \"{$sslCsrPath}\"";
            $this->excuteCommand($command);
        }

        $command = "rm \"{$caSrlPath}\"";
        $this->excuteCommand($command);

        echo "{$this->SUCCESSFUL_COLOR}ssl\t\t(successful)\n{$this->DEFAULT_COLOR}";
    }

    public function setupHosts()
    {
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

        echo "{$this->SUCCESSFUL_COLOR}hosts\t\t(successful)\n{$this->DEFAULT_COLOR}";
    }

    public function setupNginx()
    {
        foreach ($this->config['sites'] as $site) {
            if ($site['enabled']) {
                $fileName = $site['domain'];
                $template = file_get_contents($this->baseDir . '/datas/templates/nginx/' . $site['template']);
                foreach ($site as $key => $value) {
                    $template = str_replace("<$key>", $site[$key], $template);
                }

                file_put_contents("/etc/nginx/sites-enabled/$fileName", $template);
            }
        }

        $this->excuteCommand('service nginx restart');

        echo "{$this->SUCCESSFUL_COLOR}nginx\t\t(successful)\n{$this->DEFAULT_COLOR}";
    }

    public function setupMysql()
    {
        if (count(scandir('/var/lib/mysql')) == 2) {
            $this->excuteCommand('bash ' . $this->baseDir . '/src/initializeMysql.sh');
        } else {
            $this->excuteCommand('service mysql restart');
        }

        echo "{$this->SUCCESSFUL_COLOR}mysql\t\t(successful)\n{$this->DEFAULT_COLOR}";
    }

    public function setupRedis()
    {
        $this->excuteCommand('service redis-server start');

        echo "{$this->SUCCESSFUL_COLOR}redis\t\t(successful)\n{$this->DEFAULT_COLOR}";
    }

    private function getUsedPhpFpmVersions()
    {
        $result = [];
        foreach ($this->config['sites'] as $site) {
            $version = $site['php_fpm_version'];
            if (! in_array($version, $result)) {
                $result[] = $version;
            }
        }

        return $result;
    }

    private function excuteCommand($command, $redirectStdOutput = true)
    {
        if ($redirectStdOutput) {
            $command .= " > /dev/null 2>&1";
        }

        return shell_exec($command);
    }
}

(new SetupContainer())->pipeLine();
