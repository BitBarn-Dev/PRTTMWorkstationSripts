#!/bin/bash

EXTENSION="dash-to-panel@jderose9.github.com"
for user in $(ls /home); do
    if id "$user" &>/dev/null; then
        sudo -u "$user" dbus-launch dconf write /org/gnome/shell/enabled-extensions "['$EXTENSION']"
    fi
done