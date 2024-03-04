#!/bin/bash

############### Global Variable Start ##############
SCRIPT_PATH=$(cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P);
CONFIG_PATH="${SCRIPT_PATH}/config.json";
CONFIG_VERSION="1.7.0";
IMAGE_VERSION="1.11.0";
############### Global Variable End ##############


############### Helper Methods Start ##############
function contains_array()
{
    local needle=$1 el;
    shift;

    for el in "$@"; do
        if [[ $needle == *$el* ]]; then
            return 0;
        fi
    done

    return 1;
}

function copyFile()
{
    ${sudo} mkdir -p ${2};
    ${sudo} cp -p ${1} ${2};

    return 0;
}

function printText()
{
    # colors
    local DEFAULT="\033[0m";
    local color;

    # fontColor
    if [[ ${2} == 'FRED' ]]; then
        color="\033[0;31m";
    elif [[ ${2} == 'FGREEN' ]]; then
        color="\033[0;32m";
    elif [[ ${2} == 'FYELLOW' ]]; then
        color="\033[0;33m";
    elif [[ ${2} == 'BRED' ]]; then
        color="\033[1;41m";
    elif [[ ${2} == 'BGREEN' ]]; then
        color="\033[1;42m";
    elif [[ ${2} == 'BYELLOW' ]]; then
        color="\033[1;43m";
    else
        color=${DEFAULT};
    fi

    echo -e "${color}${1}${DEFAULT}";

    return 0;
}

function getJsonValue()
{
    local path=${1};
    local search=${2};

    result=$(${sudo} docker run --rm -i imega/jq < ${CONFIG_PATH} ".$search" | sed -e 's/"//g');

    return 0;
}

function setJsonValue()
{
    local path=${1};
    local search=${2};
    local value=${3};

    if ! [[ ${value} == true || ${value} == false || ${value} == null ]]; then
        value=\"$value\";
    fi;

    $(${sudo} docker run --rm -i imega/jq < ${CONFIG_PATH} ".${search} |= ${value}" --indent 4 > tmp.json);

    cat tmp.json > ${path};
    rm tmp.json;

    return 0;
}

############### Helper Methods End ################

function getSudoCommand()
{
    whoami=$(whoami 2>/dev/null);

    if ! [[ ${whoami} == "root" ]]; then
        sudo="sudo";
    else
        sudo="";
    fi

    return 0;
}

function checkSystemSupported()
{
    if contains_array ${OSTYPE} linux darwin; then
        printText 'system\t\t(successful)' 'FGREEN';
        return 0;
    else
        printText "system\(failed: not support ${OSTYPE})" "FRED";
        return 1;
    fi
}

function checkDockerIsReady()
{
    if ! [[ $(${sudo} docker images 2>/dev/null) ]]; then
        printText "docker\t\t(failed: not install or not running)" "FRED";
        return 1;
    else
        printText "docker\t\t(successful)" "FGREEN"
        return 0;
    fi
}

function setupStructure()
{
    for i in {0..1}
    do
        mkdir -p ${SCRIPT_PATH}/datas/database;

        if [ ! -f "${SCRIPT_PATH}/config.json" ]; then
            if [[ ${i} == 0 ]]; then
                copyFile "${SCRIPT_PATH}/src/templates/config/config.json" "${SCRIPT_PATH}/";
            else
                printText "structure\t(failed: can't add config.json)" "FRED";
                return 1;
            fi
        fi

        if  [ ! -f "${SCRIPT_PATH}/datas/templates/nginx/default.conf" ]; then
            if [[ ${i} == 0 ]]; then
                copyFile "${SCRIPT_PATH}/src/templates/nginx/default.conf" "${SCRIPT_PATH}/datas/templates/nginx/";
            else
                printText "structure\t(failed: can't add datas/templates/nginx/default.conf)" "FRED";
                return 1;
            fi
        fi;

        if  [ ! -f "${SCRIPT_PATH}/datas/templates/php/php-cli.ini" ]; then
            if [[ ${i} == 0 ]]; then
                copyFile "${SCRIPT_PATH}/src/templates/php/php-cli.ini" "${SCRIPT_PATH}/datas/templates/php/";
            else
                printText "structure\t(failed: can't add datas/templates/php/php-cli.ini)" "FRED";
                return 1;
            fi
        fi;

        if [ ! -f "${SCRIPT_PATH}/datas/templates/php/php-fpm.ini" ]; then
            if [[ ${i} == 0 ]]; then
                copyFile "${SCRIPT_PATH}/src/templates/php/php-fpm.ini" "${SCRIPT_PATH}/datas/templates/php/";
            else
                printText "structure\t(failed: can't add datas/templates/php/php-fpm.ini)" "FRED";
                return 1;
            fi

        fi;
    done

    printText "structure\t(successful)" "FGREEN";

    return 0;
}

function setupTrustedCa()
{
    local CA_PATH="${SCRIPT_PATH}/src/DnmpCa.crt";

    local i;
    for i in {0..1}
    do
        if [[ ${OSTYPE} == "darwin"* ]] && ! ${sudo} security verify-cert -c ${CA_PATH} > /dev/null 2>&1; then
            if [[ ${i} == 0 ]]; then
                ${sudo} security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ${CA_PATH} > /dev/null 2>&1;
                sleep 1;
            else
                printText "ca\t\t(failed: can't add trusted ca certification)" "FRED";
                return 1;
            fi
        elif [[ ${OSTYPE} == "linux"* ]] && [ ! -f "/usr/local/share/ca-certificates/DnmpCa.crt" ] || [ ! -f "/etc/pki/ca-trust/source/anchors/DnmpCa.crt" ]; then
            if [[ ${i} == 0 ]]; then
                # ubuntu
                copyFile ${CA_PATH} "/usr/local/share/ca-certificates/";
                ${sudo} update-ca-certificates > /dev/null 2>&1;

                # centos
                copyFile ${CA_PATH} "/etc/pki/ca-trust/source/anchors/";
                ${sudo} update-ca-trust > /dev/null 2>&1;
            else
                printText "ca\t\t(failed: can't add trusted ca certification)" "FRED";
                return 1;
            fi
        fi
    done

    printText "ca\t\t(successful)" "FGREEN";

    return 0;
}

function checkVersionCompatibility()
{
    getJsonValue ${CONFIG_PATH} "config_version";
    local currentConfigVersion=${result};

    if ! [[ ${currentConfigVersion} == ${CONFIG_VERSION} ]]; then
        printText "version\t\t(failed: the version of config.json has been deprecated, please refer to the document example to update your config.json format and version number)" "FRED";
        return 1;
    fi

    local i;
    for i in {0..1}
    do
        if ! [[ $(${sudo} docker images dnmp:${IMAGE_VERSION} --format {{.Repository}}:{{.Tag}}) == "dnmp:${IMAGE_VERSION}" ]]; then
            if [[ $i == 0 ]]; then
                cleanupFingerprint
                # buildImage;
                ${sudo} docker rmi $(${sudo} docker images dnmp -q) 2>/dev/null;
                ${sudo} docker build -t dnmp:${IMAGE_VERSION} ${SCRIPT_PATH}/src --no-cache;
            else
                printText "version\t\t(failed: build dnmp:${IMAGE_VERSION} image error)" "FRED";
                return 1;
            fi
        fi
    done

    printText "version\t\t(successful)" "FGREEN";

    return 0;
}

function setupHosts()
{
    getJsonValue ${CONFIG_PATH} 'sites[] | (.domain) + ";" + (.auto_host | tostring)';
    local sitesSetting domain autoHost;

    for siteSetting in ${result};
    do
        domain=$(echo $siteSetting | cut -d ";" -f 1);
        autoHost=$(echo $siteSetting | cut -d ";" -f 2);
        if [[ ${autoHost} == "true" ]]; then
            for i in {0..1}
            do
                if ! [[ $(cat /etc/hosts | grep "127.0.0.1[[:space:]]\+${domain}" 2>/dev/null) ]]; then
                    if [[ ${i} == 0 ]]; then
                        ${sudo} sh -c "echo '127.0.0.1 ${domain}' >> /etc/hosts";
                        sleep 1;
                    else
                        printText "hosts\t\t(failed: can't add \"127.0.0.1 ${domain}\" to /etc/hosts)" "FRED";
                        return 1;
                    fi
                fi
            done
        fi
    done

    printText "hosts\t\t(successful)" "FGREEN";

    return 0;
}

function setupIp()
{
    if [[ ${OSTYPE} == "darwin"* ]]; then
        local interface=$(route -n get 0.0.0.0 | grep -oe "interface:.*" | awk {'print $2'});
        local ip=$(ipconfig getifaddr $interface);
    elif [[ ${OSTYPE} == 'linux'* ]]; then
        local ip=$(hostname -I | awk '{print $1}' | sed -e 's/ //g');
    fi

    setJsonValue ${CONFIG_PATH} "ip" ${ip};
    getJsonValue ${CONFIG_PATH} "ip";

    if [[ $result == $ip ]]; then
        printText "ip\t\t(successful)" "FGREEN";
        return 0;
    else
        printText "ip\t\t(failed: can't write ip to config.json')" "FRED";
        return 1;
    fi
}

function cleanupFingerprint()
{
    getJsonValue ${CONFIG_PATH} 'ports[] | select(.container == "22" and .enabled == true) | (.local)';
    local port=${result};

    getJsonValue ${CONFIG_PATH} "ip";
    local ips="
        ${result}
        localhost
        127.0.0.1
    ";

    for ip in ${ips}
    do
        eval "ssh-keygen -R [${ip}]:${port} > /dev/null 2>&1";
    done
}

function startContainer()
{
    local command="${sudo} docker run --rm -it";

    # mapping ports
    getJsonValue ${CONFIG_PATH} 'ports[] | select(.enabled == true) | "-p " + (.local) + ":" + (.container)';
    command="${command} ${result}";

    # mapping folders
    getJsonValue ${CONFIG_PATH} 'folders[] | select(.enabled == true) | "-v " + (.local) + ":" + (.container)';
    command="${command} ${result}";

    # mapping database
    command="${command} -v ${SCRIPT_PATH}/datas/database:/var/lib/mysql";

    # mapping mongodb
    command="${command} -v ${SCRIPT_PATH}/datas/mongodb:/var/lib/mongodb";

    # mapping dnmp
    command="${command} -v ${SCRIPT_PATH}:/dnmp";

    # mapping home directory
    command="${command} -v ${SCRIPT_PATH}/datas/home:/root";

    # mongodb need to setup this options
    command="${command} --ulimit memlock=-1";

    # container name
    command="${command} --name dnmp";

    # image name
    command="${command} dnmp:${IMAGE_VERSION}";

    eval $command;

    return 0;
}

function main()
{
    printText "======= Setup Local Env =======" "FYELLOW";

    local methods="
        getSudoCommand
        checkSystemSupported
        checkDockerIsReady
        setupStructure
        setupTrustedCa
        checkVersionCompatibility
        setupHosts
        setupIp
        startContainer
    ";

    for method in ${methods}
    do
        ${method};
        if [[ ${?} == 1 ]]; then
            printText "                                                   " "BRED";
            printText "  see document: https://github.com/ntut-mika/dnmp  " "BRED";
            printText "                                                   " "BRED";
            return 1;
        fi
    done

    return 0;
}

main
