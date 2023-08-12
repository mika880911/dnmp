#!/bin/bash

function main()
{
    php8.2 /dnmp/src/SetupContainer.php
    clear
    /etc/update-motd.d/93-welcome
    bash
}

main
