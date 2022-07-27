<?php

class StartContainer
{
    protected $config;

    public function __construct()
    {
        $this->config = json_decode(file_get_contents(__DIR__ . '/../config.json'), true);
    }

    public function addTrustedCa()
    {
        $caPath = __DIR__ . '/ca.crt';
        $command = null;

        if (PHP_OS === "Darwin") {
            if (stristr(shell_exec("security verify-cert -c  {$caPath} 2>/dev/null") ?? "", "successful") === false) {
                $command = "sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain {$caPath}";
            }
        } elseif (PHP_OS === 'WINNT') {
        }

        if ($command) {
            shell_exec($command);
        }
    }

    public function modifyHosts()
    {
        $hosts = file_get_contents($this->config['hosts-path']);

        foreach ($this->config['sites'] as $site) {
            if ($site['auto_host']) {
                $domain = $site['domain'];

                if (count(preg_grep("/^(127.0.0.1)([\s\\t]*)($domain)$/", explode("\n", $hosts))) == 0) {
                    $hosts .= "\n127.0.0.1 $domain";
                }
            }
        }

        file_put_contents($this->config['hosts-path'], $hosts);
    }

    public function getStartContainerCommand()
    {
        $pwd = getcwd();
        $command = "docker run --rm -it";

        # mapping ports
        foreach ($this->config['ports'] as $hostPort => $containerPort) {
            $command .= " -p ${hostPort}:${containerPort}";
        }

        # mapping folders
        foreach ($this->config['folders'] as $folder) {
            $source = $folder['source'];
            $source = $this->transferPathToAbsolute($folder['source']);
            $dist = $folder['dist'];

            $command .= " -v $source:$dist";
        }

        # mapping database
        $command .= " -v {$this->transferPathToAbsolute(__DIR__ . '/../datas/database')}:/var/lib/mysql";
        # mapping dnmp
        $command .= " -v {$this->transferPathToAbsolute(__DIR__ . '/../')}:/dnmp";

        # image name
        $command .= ' dnmp';

        return $command;
    }

    private function transferPathToAbsolute($path)
    {
        if (! is_dir($path)) {
            $fileName = basename($path);
            $path = dirname($path);
        } else {
            $fileName = null;
        }

        if (PHP_OS === 'WINNT') {
            $result = trim(shell_exec("cd $path && cd"));
        } else {
            $result = trim(shell_exec("cd $path && pwd"));
        }

        if ($fileName) {
            $result .= "/$fileName";
        }

        $result = str_replace('\\', '/', $result);

        return $result;
    }

    public function modifyXdebugIni()
    {
        $xdebugIniPath = __DIR__ . '/../datas/templates/php/xdebug.ini';
        $xdebugIni = file_get_contents($xdebugIniPath);

        $currentIp = gethostbyname(gethostname());
        $xdebugIni = preg_replace('/xdebug.client_host=(.*)/', 'xdebug.client_host=' . $currentIp, $xdebugIni);
        $xdebugIni = preg_replace('/xdebug.remote_host=(.*)/', 'xdebug.remote_host=' . $currentIp, $xdebugIni);

        file_put_contents($xdebugIniPath, $xdebugIni);
    }

    public function run()
    {
        $this->addTrustedCa();
        $this->modifyHosts();
        $this->modifyXdebugIni();
        echo $this->getStartContainerCommand();
    }
}

$app = new StartContainer();
$app->run();
