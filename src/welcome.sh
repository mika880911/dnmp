#!/bin/bash

function main()
{
    local default="\033[0m";
    local color="\033[1;34m";

    echo -e "${color}=================================================================== ${default}";
    echo -e "${color} _      __    __                 ______     ___  _  ____  ______    ${default}";
    echo -e "${color}| | /| / /__ / /______  __ _  __/_  __/__  / _ \/ |/ /  |/  / _ \   ${default}";
    echo -e "${color}| |/ |/ / -_) / __/ _ \/  ' \/ -_) / / _ \/ // /    / /|_/ / ___/   ${default}";
    echo -e "${color}|__/|__/\__/_/\__/\___/_/_/_/\__/_/  \___/____/_/|_/_/  /_/_/       ${default}";
    echo -e "${color}\n=================================================================== ${default}";
}

main
