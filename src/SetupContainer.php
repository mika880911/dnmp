<?php

namespace Mika\Dnmp;

class SetupContainer
{
    protected $ERROR_COLOR        = "\033[0;31m";
    protected $SUCCESSFUL_COLOR   = "\033[0;32m";
    protected $DEFAULT_COLOR      = "\033[0m";
    protected $INFO_COLOR         = "\033[0;33m";

    protected $config;

    protected $baseDir = __DIR__ . '/..';

    public function __construct()
    {
        $this->config = json_decode(file_get_contents("{$this->baseDir}/config.json"), true);
        $this->config['sites'] = $this->getReplacedSites($this->config['sites']);
    }

    public function pipeLine()
    {
        $this->echo("======= Setup Container Env =======\n", $this->INFO_COLOR);
        $this->setupPhp();
        $this->setupComposer();
        $this->setupSSL();
        $this->setupHosts();
        $this->setupNginx();
        $this->setupMysql();
        $this->setupRedis();
        $this->setupCronJob();
        $this->setupSupervisor();
        $this->setupSsh();
    }

    public function setupPhp()
    {
        // setup php-cli version
        $phpCliVersion = $this->config['php_cli_version'];
        $availableVersion = ['5.6', '7.0', '7.1', '7.2', '7.3', '7.4', '8.0', '8.1', '8.2'];

        $cliIni       = file_get_contents("{$this->baseDir}/datas/templates/php/php-cli.ini");
        $fpmIni       = file_get_contents("{$this->baseDir}/datas/templates/php/php-fpm.ini");
        $xdebugIni    = '';

        if ($this->config['xdebug']['enabled']) {
            $xdebugIni  = "zend_extension=xdebug.so\n";
            // xdebug 2
            $xdebugIni .= "xdebug.remote_enable=1\n";
            $xdebugIni .= "xdebug.remote_autostart=1\n";
            $xdebugIni .= "xdebug.remote_port={$this->config['xdebug']['port']}\n";
            $xdebugIni .= "xdebug.remote_host={$this->config['ip']}\n";

            // xdebug 3
            $xdebugIni .= "xdebug.mode=develop,coverage,debug,profile\n";
            $xdebugIni .= "xdebug.start_with_request=yes\n";
            $xdebugIni .= "xdebug.client_port={$this->config['xdebug']['port']}\n";
            $xdebugIni .= "xdebug.client_host={$this->config['ip']}\n";

            $xdebugIni .= "xdebug.idekey={$this->config['xdebug']['idekey']}";
        }

        // setup php.ini and start service
        foreach ($availableVersion as $phpVersion) {
            file_put_contents("/etc/php/{$phpVersion}/cli/php.ini", $cliIni);
            file_put_contents("/etc/php/{$phpVersion}/fpm/php.ini", $fpmIni);
            file_put_contents("/etc/php/{$phpVersion}/mods-available/xdebug.ini", $xdebugIni);
            $this->executeCommand("service php{$phpVersion}-fpm start");
        }

        // setup php soft link
        if (in_array($phpCliVersion, $availableVersion)) {
            $this->executeCommand('rm /etc/alternatives/php');
            $this->executeCommand("ln -s /usr/bin/php{$phpCliVersion} /etc/alternatives/php");
            $this->echo("php({$phpCliVersion})\t(successful)\n", $this->SUCCESSFUL_COLOR);
        } else {
            $this->echo("php({$phpCliVersion})\t(failed: version not allow)\n", $this->ERROR_COLOR);
        }
    }

    public function setupComposer()
    {
        $composerVersion    = $this->config['composer_version'];
        $availableVersion   = [1, 2];

        $this->executeCommand('new_path="export PATH=\"\$HOME/.config/composer/vendor/bin:\$PATH\""; bashrc_file="$HOME/.bashrc"; if ! cat "$bashrc_file" | grep -qF "$new_path"; then echo "$new_path" >> "$bashrc_file";fi', false);

        if (in_array($composerVersion, $availableVersion)) {
            $this->executeCommand("composer self-update --{$composerVersion}");
            $this->echo("composer({$composerVersion})\t(successful)\n", $this->SUCCESSFUL_COLOR);
        } else {
            $this->echo("composer({$composerVersion})\t(failed: version not allow)\n", $this->ERROR_COLOR);
        }
    }

    public function setupSSL()
    {
        $caCrtPath = "{$this->baseDir}/src/DnmpCa.crt";
        $caKeyPath = "{$this->baseDir}/src/DnmpCa.key";
        $caSrlPath = "{$this->baseDir}/src/DnmpCa.srl";

        copy($caCrtPath, '/usr/local/share/ca-certificates/DnmpCa.crt');
        $this->executeCommand('update-ca-certificates');

        foreach ($this->config['sites'] as $site) {
            $domain   = $site['domain'];
            $sslDir = "{$this->baseDir}/datas/ssl/{$domain}";
            $this->executeCommand("mkdir -p '$sslDir'");

            $sslCrtPath = "{$sslDir}/ssl.crt";
            $sslKeyPath = "{$sslDir}/ssl.key";
            $sslCsrPath = "{$sslDir}/ssl.csr";

            if (file_exists($sslCrtPath) && file_exists($sslKeyPath)) {
                $expiredAt = openssl_x509_parse(file_get_contents($sslCrtPath))['validTo_time_t'];

                // renew the certificate if it expires after 30 days
                if ($expiredAt > time() + 60 * 60 * 24 * 30) {
                    continue;
                }
            }

            // generate ssl.key
            $this->executeCommand("openssl genrsa -out \"{$sslKeyPath}\" 4096");

            // generate ssl.csr
            $this->executeCommand("openssl req -key \"{$sslKeyPath}\" -out \"{$sslCsrPath}\" -subj \"/CN={$domain}\" -new -sha256");

            // generate ssl.crt
            $this->executeCommand("bash -c 'openssl x509 -req -sha256 -days 365 -in \"{$sslCsrPath}\" -out \"{$sslCrtPath}\" -CA \"{$caCrtPath}\" -CAkey \"{$caKeyPath}\" -extfile <(printf \"subjectAltName=DNS:{$domain},IP:127.0.0.1\\nextendedKeyUsage = serverAuth\") -CAcreateserial'");

            // remove ssl.csr
            $this->executeCommand("rm \"{$sslCsrPath}\"");
        }

        // remove DnmpCa.srl
        $this->executeCommand("rm \"{$caSrlPath}\"");
        $this->echo("ssl\t\t(successful)\n", $this->SUCCESSFUL_COLOR);
    }

    public function setupHosts()
    {
        $hosts = file_get_contents('/etc/hosts');

        foreach ($this->config['sites'] as $site) {
            if ($site['auto_host']) {
                if (count(preg_grep("/^(127.0.0.1)([\s\\t]*)({$site['domain']})$/", explode("\n", $hosts))) == 0) {
                    $hosts .= "\n127.0.0.1 {$site['domain']}";
                }
            }
        }

        file_put_contents('/etc/hosts', $hosts);

        if (file_get_contents('/etc/hosts') == $hosts) {
            $this->echo("hosts\t\t(successful)\n", $this->SUCCESSFUL_COLOR);
        } else {
            $this->echo("hosts\t\t(failed: can't write /etc/hsots)\n", $this->ERROR_COLOR);
        }
    }

    public function setupNginx()
    {
        foreach ($this->config['sites'] as $site) {
            if ($site['enabled']) {
                file_put_contents("/etc/nginx/sites-enabled/{$site['domain']}", $site['nginx_template_content']);
            }
        }

        $this->executeCommand('service nginx restart');

        if ($this->executeCommand('nginx -t', true, true) == 0) {
            $this->echo("nginx\t\t(successful)\n", $this->SUCCESSFUL_COLOR);
        } else {
            $this->echo("nginx\t\t(failed: datas/templates/nginx/* configuration incorrect)\n", $this->ERROR_COLOR);
        }
    }

    public function setupMysql()
    {
        if (count(scandir('/var/lib/mysql')) == 2) {
            $this->executeCommand("bash {$this->baseDir}/src/initializeMysql.sh");
        } else {
            $this->executeCommand('service mysql restart');
        }

        if ($this->executeCommand('mysqladmin -h 127.0.0.1 -uroot processlist', true, true) == 0) {
            $this->echo("mysql\t\t(successful)\n", $this->SUCCESSFUL_COLOR);
        } else {
            $this->echo("mysql\t\t(failed: can't start mysql server, delete the data/database directory may fix this problem)\n", $this->ERROR_COLOR);
        }
    }

    public function setupRedis()
    {
        $this->executeCommand('service redis-server start');

        if ($this->executeCommand('redis-cli -h 127.0.0.1 -p 6379 ping', true, true) == 0) {
            $this->echo("redis\t\t(successful)\n", $this->SUCCESSFUL_COLOR);
        } else {
            $this->echo("redis\t\t(failed can't start redis server)\n", $this->ERROR_COLOR);
        }
    }

    public function setupCronJob()
    {
        foreach ($this->config['sites'] as $site) {
            if ($site['enabled']) {
                foreach ($site['cronjobs'] as $cronJob) {
                    if ($cronJob['enabled']) {
                        $this->executeCommand("crontab -l 2>/dev/null | { cat; echo \"{$cronJob['job']}\"; } | crontab -");
                    }
                }
            }
        }

        $this->executeCommand('service cron start');
        $this->echo("cronjob\t\t(successful)\n", $this->SUCCESSFUL_COLOR);
    }

    public function setupSupervisor()
    {
        foreach ($this->config['sites'] as $site) {
            if ($site['enabled']) {
                foreach ($site['supervisors'] as $supervisor) {
                    if ($supervisor['enabled']) {
                        $programName = $site['domain'] . '-' . bin2hex(random_bytes(5));
                        $supervisorContent = "[program:{$programName}]\n";
                        foreach ($supervisor as $key => $value) {
                            if ($key != 'enabled') {
                                $supervisorContent .= "{$key}={$value}\n";
                            }
                        }

                        file_put_contents("/etc/supervisor/conf.d/{$programName}.conf", $supervisorContent);
                    }
                }
            }
        }

        $this->executeCommand('service supervisor start', true, true);
        $this->echo("supervisor\t(successful)\n", $this->SUCCESSFUL_COLOR);
    }

    public function setupSsh()
    {
        $this->executeCommand('service ssh start', true, true);
        $this->echo("ssh\t\t(successful)\n", $this->SUCCESSFUL_COLOR);
    }

    private function executeCommand($command, $redirectStdOutput = true, $getExitCode = false)
    {
        if ($redirectStdOutput) {
            $command .= " > /dev/null 2>&1";
        }

        if ($getExitCode) {
            $command .= '; echo $?';
        }

        return shell_exec($command);
    }

    private function getReplacedSites($sites)
    {
        foreach ($sites as &$site) {
            $replaceRules = [];
            foreach ($site as $key => $value) {
                if (! is_iterable($value)) {
                    $replaceRules["<$key>"] = $value;
                }
            }

            foreach ($site as $key => $value) {
                if (! is_iterable($value)) {
                    $replaceRules["<$key>"] = str_replace(array_keys($replaceRules), array_values($replaceRules), $value);
                }
            }

            $replaceFrom = array_keys($replaceRules);
            $replaceTo = array_values($replaceRules);

            foreach ($site as $key => $value) {
                if (! is_iterable($value)) {
                    $site[$key] = str_replace($replaceFrom, $replaceTo, $value);
                }
            }

            // load nginx template
            $site['nginx_template_content'] = str_replace($replaceFrom, $replaceTo, file_get_contents("{$this->baseDir}/datas/templates/nginx/{$site['nginx_template']}"));

            // replace array object
            $processKeys = ['cronjobs', 'supervisors'];
            foreach ($processKeys as $processKey) {
                foreach ($site[$processKey] as $index => $target) {
                    foreach ($target as $key => $value) {
                        if (! is_iterable($value)) {
                            $site[$processKey][$index][$key] = str_replace($replaceFrom, $replaceTo, $value);
                        }
                    }
                }
            }
        }

        return $sites;
    }

    private function echo($string, $color)
    {
        echo "{$color}{$string}{$this->DEFAULT_COLOR}";
    }
}

(new \Mika\Dnmp\SetupContainer())->pipeLine();
