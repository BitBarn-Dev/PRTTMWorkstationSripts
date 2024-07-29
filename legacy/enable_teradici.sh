#!/usr/bin/env bash

echo "Content-type: text/html"
echo ""

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 1|0"
    exit 1
fi

if [ "$1" -eq 1 ]; then
    echo "Enabling PCoIP and disabling GDM and DCV server"
    sudo /usr/bin/systemctl disable --now gdm > /dev/null 2>&1
    sleep 5
    sudo /usr/bin/systemctl disable --now dcvserver > /dev/null 2>&1
    sleep 5
    sudo /usr/bin/rm /etc/X11/xorg.conf.d/dcv.conf
    sleep 1
    sudo /usr/bin/systemctl enable --now pcoip > /dev/null 2>&1
elif [ "$1" -eq 0 ]; then
    echo "Disabling PCoIP and enabling GDM and DCV server"
    sudo /usr/bin/systemctl disable --now pcoip > /dev/null 2>&1
    sleep 5
    sudo /usr/bin/systemctl enable --now dcvserver > /dev/null 2>&1
    sleep 5
    sudo /usr/bin/systemctl enable --now gdm > /dev/null 2>&1
else
    echo "Invalid parameter. Usage: $0 1|0"
    exit 1
fi