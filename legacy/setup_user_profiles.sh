#!/bin/bash
set -x
LOGFILE="/var/log/setup_user_profiles.log"

DOMAIN="prttm.dev"
USERNAME=${PAM_USER}
if [ -z "$USERNAME" ]; then
    echo "No username provided. Exiting." | sudo tee -a $LOGFILE
    exit 1
fi

FULL_USERNAME="${USERNAME}@${DOMAIN}"
USER_HOME="/home/${FULL_USERNAME}"
PROFILE_DIR="/mnt/userprofiles/${FULL_USERNAME}"
MOUNT_POINT="/mnt/shared"

{
echo "Running setup_user_profiles.sh for user: $FULL_USERNAME"
echo "User home directory: $USER_HOME"
echo "Profile directory: $PROFILE_DIR"

# Ensure the mount point directory exists
if [ ! -d "$MOUNT_POINT" ]; then
    echo "Creating mount point directory: $MOUNT_POINT"
    sudo mkdir -p "$MOUNT_POINT"
fi

# Attempt to mount the user profile
echo "Attempting to mount the user profile share"
sudo mount -t cifs //192.168.1.85/shared "$MOUNT_POINT" -o username=artist,password=password,uid=1000,gid=1000,file_mode=0777,dir_mode=0777,vers=3.0

# Check if the profile directory exists on the network share
if [ ! -d "$PROFILE_DIR" ]; then
    echo "Profile directory does not exist: $PROFILE_DIR"
    echo "Creating profile directory from template"
    /usr/local/bin/create_user_from_template.sh "$FULL_USERNAME"
fi

# Check if the user home directory exists and is a symlink
if [ ! -L "$USER_HOME" ]; then
    echo "Removing existing home directory or symlink: $USER_HOME"
    sudo rm -rf "$USER_HOME"
    echo "Creating symlink from $USER_HOME to $PROFILE_DIR"
    sudo ln -s "$PROFILE_DIR" "$USER_HOME"
fi

echo "Setup complete for user: $FULL_USERNAME"
} | sudo tee -a $LOGFILE