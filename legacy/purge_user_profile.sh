#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 username"
    exit 1
fi

USERNAME=$1
HOME_DIR="/home/$USERNAME"
LOGFILE="/var/log/purge_user_profile.log"

echo "Purging user profile for: $USERNAME" | sudo tee -a $LOGFILE

# Check if the user home directory exists
if [ -d "$HOME_DIR" ]; then
    echo "Removing home directory: $HOME_DIR" | sudo tee -a $LOGFILE
    sudo rm -rf "$HOME_DIR"
else
    echo "Home directory does not exist: $HOME_DIR" | sudo tee -a $LOGFILE
fi

# Remove cached credentials and configurations
echo "Clearing SSSD cache" | sudo tee -a $LOGFILE
sudo sss_cache -E

echo "Restarting SSSD service" | sudo tee -a $LOGFILE
sudo systemctl restart sssd

echo "User profile purge complete for: $USERNAME" | sudo tee -a $LOGFILE