<?php

class StartContainer
{
    protected $config;

    public function __construct()
    {
        $this->config = json_decode(file_get_contents(__DIR__ . '/../config.json'), true);
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

        file_put_contents('/etc/hosts', $hosts);
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
        $command .= ' -v ' . $this->transferPathToAbsolute(__DIR__ . '/../datas/database') . ':/var/lib/mysql';

        # mapping dnmp
        $command .= ' -v ' . $this->transferPathToAbsolute(__DIR__ . '/../') . ':/dnmp';

        # image name
        $command .= ' dnmp';

        echo $command;
    }

    private function transferPathToAbsolute($path)
    {
        if (! is_dir($path)) {
            $fileName = basename($path);
            $path = dirname($path);
        } else {
            $fileName = null;
        }

        $result = trim(shell_exec("cd $path && pwd"));

        if ($fileName) {
            $result .= "/$fileName";
        }

        return $result;
    }

    public function run()
    {
        $this->modifyHosts();
        $this->getStartContainerCommand();
    }
}

$app = new StartContainer();
$app->run();
