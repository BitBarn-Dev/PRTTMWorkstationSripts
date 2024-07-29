#!/bin/bash

LOGFILE="/var/log/create_user_from_template.log"

FULL_USERNAME=$1
if [ -z "$FULL_USERNAME" ]; then
    echo "No username provided. Exiting." | sudo tee -a $LOGFILE
    exit 1
fi

PROFILE_DIR="/mnt/userprofiles/$FULL_USERNAME"
TEMPLATE_DIR="/mnt/userprofiles/template_profile"

echo "Running create_user_from_template.sh for user: $FULL_USERNAME" | sudo tee -a $LOGFILE

# Create the profile directory in the network share if it does not exist
if [ ! -d "$PROFILE_DIR" ]; then
    echo "Creating profile directory on the network share: $PROFILE_DIR" | sudo tee -a $LOGFILE
    sudo mkdir -p "$PROFILE_DIR"
    sudo cp -a "$TEMPLATE_DIR/." "$PROFILE_DIR/"
    sudo chown -R "$FULL_USERNAME:domain users" "$PROFILE_DIR"
    sudo chmod -R 700 "$PROFILE_DIR"
fi

# Import dconf settings
echo "Importing dconf settings for user: $FULL_USERNAME" | sudo tee -a $LOGFILE
sudo -u "$FULL_USERNAME" dconf load /org/gnome/desktop/ < "$PROFILE_DIR/dconf-settings.ini"

echo "Profile created for user: $FULL_USERNAME" | sudo tee -a $LOGFILE