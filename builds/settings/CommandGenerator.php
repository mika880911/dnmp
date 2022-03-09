<?php

Class CommandGenerator
{
    protected $configPath = __DIR__ . '/../../volumes/settings/config.json';
    public $config;

    public function __construct()
    {
        $this->config = json_decode(file_get_contents($this->configPath), true);
    }

    /**
     * 生成啟動 docker 容器的指令
     */
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

    /**
     * 設定 /etc/hosts 文件
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

    public function generate()
    {        
        $this->configurationHosts();
        $this->generateDockerContainerCommand();
    }
}

$container = new CommandGenerator();
$container->generate();
