############### Global Variable Start ##############
$SCRIPT_PATH=$PSScriptRoot
$CONFIG_PATH="$SCRIPT_PATH/config.json"
$CONFIG_VERSION="1.7.0"
$IMAGE_VERSION="1.7.0"
############### Global Variable End ##############


############### Helper Methods Start ##############
function printText()
{
    $fColor = ""
    $bColor = ""

    if ($args[1] -eq "FRED") {
        $fColor = "RED"
    } elseif ($args[1] -eq "FGREEN") {
        $fColor = "GREEN"
    } elseif ($args[1] -eq "FYELLOW") {
        $fColor = "YELLOW"
    } elseif ($args[1] -eq "BRED") {
        $bColor = "RED"
        $fColor = "WHITE"
    } elseif ($args[1] -eq "BGREEN") {
        $bColor = "GREEN"
        $fColor = "BLACK"
    } elseif ($args[1] -eq "BYELLOW") {
        $bColor = "YELLOW"
        $fColor = "BLACK"
    }


    if ($fColor -eq "" -and $bColor -eq "") {
        Write-Host $args[0]
    } elseif ($fColor -ne "" -and $bColor -eq "") {
        WriTe-Host $args[0] -ForegroundColor $fColor
    } elseif ($fColor -eq "" -and $bColor -ne "") {
        WriTe-Host $args[0] -BackgroundColor $bColor
    } else {
        WriTe-Host $args[0] -ForegroundColor $fColor -BackgroundColor $bColor
    }
}

function copyFile()
{
    New-Item -ItemType Directory -Force -Path $args[1]
    Copy-Item $args[0] -Destination $args[1]

    return 0
}

function getJsonValue()
{
    $path = $args[0]
    $search = $args[1]
    $result = type $path | docker run --rm -i imega/jq ".$search"

    if ($result -ne $null) {
        $result = $result.replace('"', '')
    }

    return $result
}


function setJsonValue()
{
    $path = $args[0]
    $search = $args[1]
    $value = $args[2]

    if (-not $($value -eq $true -or $value -eq $false -or $value -eq $null)) {
        $value = "`"`"$value`"`""
    }


    type $path | docker run --rm -i imega/jq ".$search |= $value" --indent 4 > tmp.json
    (Get-Content -path tmp.json) | Set-Content -Encoding Default -Path $path
    Remove-Item tmp.json

    return 0
}
############### Helper Methods End ##############
function checkIsAdmin()
{
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        printText "permission`t(failed: permission denied)" "FRED"
        return 1
    } else {
        printText "permission`t(successful)" "FGREEN"
        return 0
    }
}

function checkDockerIsReady()
{
    try {
        $result = docker images 2>$null
        if ($?) {
            printText "docker`t`t(successful)" "FGREEN"
            return 0
        } else {
            throw "";
        }
    } catch {
        printText "docker`t`t(failed: not install or not running)" "FRED"
        return 1
    }
}

function setupStructure()
{
    New-Item -ItemType Directory -Force -Path $SCRIPT_PATH/datas/database
    if (-not (Test-Path -Path "$SCRIPT_PATH/config.json" -PathType Leaf)) {
        try {
            copyFile "$SCRIPT_PATH/src/templates/config/config.json" "$SCRIPT_PATH/"
        } catch {
            printText "structure`t(failed: can't add config.json)" "FRED"
            return 1
        }
    }

    if (-not (Test-Path -Path "$SCRIPT_PATH/datas/templates/nginx/default.conf" -PathType Leaf)) {
        try {
            copyFile "$SCRIPT_PATH/src/templates/nginx/default.conf" "$SCRIPT_PATH/datas/templates/nginx/"
        } catch {
            printText "structure`t(failed: can't add datas/templates/nginx/default.conf)" "FRED"
            return 1
        }
    }

    if (-not (Test-Path -Path "$SCRIPT_PATH/datas/templates/php/php-cli.ini" -PathType Leaf)) {
        try {
            copyFile "$SCRIPT_PATH/src/templates/php/php-cli.ini" "$SCRIPT_PATH/datas/templates/php/"
        } catch {
            printText "structure`t(failed: can't add datas/templates/php/php-cli.ini)" "FRED"
            return 1
        }
    }

    if (-not (Test-Path -Path "$SCRIPT_PATH/datas/templates/php/php-fpm.ini" -PathType Leaf)) {
        try {
            copyFile "$SCRIPT_PATH/src/templates/php/php-fpm.ini" "$SCRIPT_PATH/datas/templates/php/"
        } catch {
            printText "structure`t(failed: can't add datas/templates/php/php-fpm.ini)" "FRED"
            return 1
        }
    }

    printText "structure`t(successful)" "FGREEN"
}

function setupTrustedCa()
{
    try {
        Import-Certificate -FilePath "$SCRIPT_PATH/src/DnmpCa.crt" -CertStoreLocation Cert:\LocalMachine\Root
        printText "ca`t`t(successful)" "FGREEN"
        return 0
    } catch {
        printText "ca`t`t(failed: can't add trusted ca certification)" "FRED"
        return 1
    }
}

function checkVersionCompatibility()
{
    $currentConfigVersion = getJsonValue $CONFIG_PATH "config_version"

    if ($currentConfigVersion -ne $CONFIG_VERSION) {
        printText "version`t`t(failed: the version of config.json has been deprecated, please refer to the document example to update your config.json format and version number)" "FRED"
        return 1
    }

    for ($i = 0; $i -lt 2; $i++) {
        try {
            $currentImageVersion = docker images dnmp:$IMAGE_VERSION --format "{{.Repository}}:{{.Tag}}"

            if ($currentImageVersion -ne "dnmp:$IMAGE_VERSION") {
                if ($i -eq 0) {
                    # buildImage
                    $imageIds = docker images dnmp -q

                    if ($imageIds) {
                        docker rmi $imageIds
                    }

                    $env:BUILDKIT_PROGRESS="plain"
                    docker build -t dnmp:$IMAGE_VERSION "$SCRIPT_PATH/src" --no-cache
                } else {
                    throw ""
                    return 1
                }
            }
        } catch {
            printText "version`t`t(failed: build dnmp:$IMAGE_VERSION image error)" "FRED"
            return 1
        }
    }

    printText "version`t`t(successful)" "FGREEN"

    return 0
}

function setupHosts()
{
    $siteSettings = getJsonValue $CONFIG_PATH 'sites[] | (.domain) + \";\" + (.auto_host | tostring)'
    $hostsPath = "$env:windir\System32\drivers\etc\hosts"

    foreach ($siteSetting in $siteSettings) {
        $tmp = $siteSetting -split ";"
        $domain = $tmp[0]
        $autoHost = $tmp[1]
        if ($autoHost -eq $true) {
            for ($i = 0; $i -lt 2; $i++) {
                try {
                    $result = Get-Content -Path "$env:windir\System32\drivers\etc\hosts" | Select-String -Pattern "127.0.0.1\s+$domain"
                    if (-not $result) {
                        if ($i -eq 0) {
                            Add-Content -Path $hostsPath -Value "127.0.0.1`t$domain" -Force
                        } else {
                            throw ""
                        }
                    }
                } catch {
                    printText "hosts`t`t(failed: can't add `"127.0.0.1 $domain`" to $hostsPath)" "FRED"
                }
            }
        }
    }

    printText "hosts`t`t(successful)" "FGREEN"

    return 0
}

function setupIp()
{
    $ip = (Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -ne "Disconnected" }).IPv4Address.IPAddress

    setJsonValue $CONFIG_PATH "ip" $ip
    $currentCofnigIp = getJsonValue $CONFIG_PATH "ip"

    if ($currentCofnigIp -eq $ip) {
        printText "ip`t`t(successful)" "FGREEN"
        return 0
    } else {
        printText "ip`t`t(failed: can't write ip to config.json')" "FRED"
        return 1
    }
}

function startContainer()
{
    $command = "docker run --rm -it"

    # mapping ports
    $ports = getJsonValue $CONFIG_PATH 'ports[] | select(.enabled == true) | \"-p \" + (.local) + \":\" + (.container)'
    $command = "$command $ports"

    # mapping folders
    $folders = getJsonValue $CONFIG_PATH 'folders[] | select(.enabled == true) | \"-v \" + (.local) + \":\" + (.container)'
    $command = "$command $folders"

    # mapping database
    $command = "$command -v $SCRIPT_PATH/datas/database:/var/lib/mysql"

    # mapping dnmp
    $command = "$command -v ${SCRIPT_PATH}:/dnmp"

    # container name
    $command = "$command --name dnmp"

    # image name
    $command = "$command dnmp:$IMAGE_VERSION"

    Invoke-Expression $command;

    return 0
}

function main()
{
    printText "======= Setup Local Env =======" "FYELLOW"
    $methods="checkIsAdmin", "checkDockerIsReady", "setupStructure", "setupTrustedCa", "checkVersionCompatibility", "setupHosts", "setupIp"
    foreach ($method in $methods) {
        $result=&$method
        if ($result -eq 1) {
            exit 1
        }
    }

    startContainer
}

main
