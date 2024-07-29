#!/bin/bash
for user_dir in /home/*/; do
    username=$(basename "$user_dir")
    sudo -u "$username" gnome-extensions enable dash-to-panel@jderose9.github.com
done
