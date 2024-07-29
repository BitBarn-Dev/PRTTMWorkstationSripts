#!/bin/bash

USERNAME="$PAM_USER"
USER_HOME="/home/$USERNAME"
PROFILE_DIR="/mnt/userprofiles/$USERNAME"
ging print statements
echo "Running setup_user_profiles.sh for user: $USERNAME" | sudo tee -a /var/log/user_profile_setup.log
echo "User home directory: $USER_HOME" | sudo tee -a /var/log/user_profile_setup.log
echo "Profile directory: $PROFILE_DIR" | sudo tee -a /var/log/user_profile_setup.log

# Remove existing home directory if it exists and is a symlink
if [ -L "$USER_HOME" ]; then
    echo "Removing existing symlink home directory: $USER_HOME" | sudo tee -a /var/log/user_profile_setup.log
    sudo rm -f "$USER_HOME"
elif [ -d "$USER_HOME" ]; then
    echo "Removing existing home directory: $USER_HOME" | sudo tee -a /var/log/user_profile_setup.log
    sudo rm -rf "$USER_HOME"
fi

# Create the profile directory in the network share if it does not exist
if [ ! -d "$PROFILE_DIR" ]; then
    echo "Creating profile directory on the network share: $PROFILE_DIR" | sudo tee -a /var/log/user_profile_setup.log
    sudo mkdir -p "$PROFILE_DIR" || { echo "Failed to create directory $PROFILE_DIR"; exit 1; }
    sudo chown "$USERNAME:domain users" "$PROFILE_DIR" || { echo "Failed to change ownership of $PROFILE_DIR"; exit 1; }
else
    echo "Profile directory already exists: $PROFILE_DIR" | sudo tee -a /var/log/user_profile_setup.log
fi

# Create the user's home directory symlink to the network share
echo "Creating symlink from $USER_HOME to $PROFILE_DIR" | sudo tee -a /var/log/user_profile_setup.log
sudo ln -s "$PROFILE_DIR" "$USER_HOME" || { echo "Failed to create symlink $USER_HOME"; exit 1; }

# Ensure the bind mount is persistent by adding it to /etc/fstab if not already there
if ! grep -q "$PROFILE_DIR" /etc/fstab; then
    echo "Adding bind mount to /etc/fstab" | sudo tee -a /var/log/user_profile_setup.log
    echo "$PROFILE_DIR $USER_HOME none bind 0 0" | sudo tee -a /etc/fstab
else
    echo "Bind mount already in /etc/fstab" | sudo tee -a /var/log/user_profile_setup.log
fi

# Reload systemd to apply changes in fstab
sudo systemctl daemon-reload

# Bind mount the profile directory to the user's home directory
echo "Bind mounting $PROFILE_DIR to $USER_HOME" | sudo tee -a /var/log/user_profile_setup.log
sudo mount --bind "$PROFILE_DIR" "$USER_HOME" || { echo "Failed to bind mount $PROFILE_DIR"; exit 1; }

# Verify the mount
if mountpoint -q "$USER_HOME"; then
    echo "Successfully mounted $PROFILE_DIR to $USER_HOME" | sudo tee -a /var/log/user_profile_setup.log
else
    echo "Failed to mount $PROFILE_DIR to $USER_HOME" | sudo tee -a /var/log/user_profile_setup.log
fi