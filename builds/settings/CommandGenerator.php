<?php

Class CommandGenerator
{
    protected $configPath = __DIR__ . '/../../volumes/settings/config.json';

    public $config;

    public function __construct()
    {
        $this->config = json_decode(file_get_contents($this->configPath), true);
    }

    public function generateDockerContainerCommand()
    {
        $pwd = getcwd();
        $command = "docker run --rm -it ";

        $ports = $this->config['ports'];
        foreach ($ports as $key => $value) {
            $command .= "-p $key:$value ";
        }

        $command .= "-v $pwd/volumes/database:/var/lib/mysql ";
        $command .= "-v $pwd/volumes/settings:/settings ";

        $folders = $this->config['folders'];
        foreach ($folders as $folder) {
            $source = $folder['source'];
            $source = trim(shell_exec("cd $source && pwd"));
            $dist = $folder['dist'];

            $command .= "-v $source:$dist ";
        }

        $command .= 'dnmp';

        echo $command;
    }

    public function configurationHosts()
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
    }

    public function generate()
    {
        $this->configurationHosts();
        $this->generateDockerContainerCommand();
    }
}

$container = new CommandGenerator();
$container->generate();
