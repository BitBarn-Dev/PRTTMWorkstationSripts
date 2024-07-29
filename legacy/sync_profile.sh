#!/bin/bash
while true; do
  AUTHFILE=$(find /run/user/$(id -u gdm)/gdm/ -name 'Xauthority' | head -n 1)
  if [ -z "$AUTHFILE" ]; then
    AUTHFILE=$(find /home/*/.Xauthority | head -n 1)
  fi
  if [ -n "$AUTHFILE" ]; then
    /usr/bin/x11vnc -forever -shared -rfbport 5900 -rfbauth /etc/x11vnc.pass -auth $AUTHFILE -display :0 -noxdamage -nomodtweak -noxrecord -noxfixes -nossl
  else
    echo "No Xauthority file found. Retrying in 10 seconds..."
    sleep 10
  fi
done
#!/bin/bash
while true; do
  AUTHFILE=$(find /run/user/$(id -u)/gdm/ -name 'Xauthority' | head -n 1)
  if [ -z "$AUTHFILE" ]; then
    AUTHFILE=$(find /home/*/.Xauthority | head -n 1)
  fi
  if [ -n "$AUTHFILE" ]; then
    /usr/bin/x11vnc -forever -shared -rfbport 5900 -rfbauth /etc/x11vnc.pass -auth $AUTHFILE -display :0 -noxdamage -nomodtweak -noxrecord -noxfixes -nossl
  else
    echo "No Xauthority file found. Retrying in 10 seconds..."
    sleep 10
  fi
done

[root@Lin010 bin]# cat sync_profile.sh
#!/bin/bash

USER_HOME="/home/$PAM_USER"
PROFILE_DIR="/mnt/shared/$PAM_USER"

# Synchronize profile at login
if [ "$PAM_TYPE" = "open_session" ]; then
    echo "Synchronizing profile at login for user: $PAM_USER" | sudo tee -a /var/log/sync_profile.log
    rsync -a --delete "$PROFILE_DIR/.config/" "$USER_HOME/.config/" | sudo tee -a /var/log/sync_profile.log
    rsync -a --delete "$PROFILE_DIR/.local/share/" "$USER_HOME/.local/share/" | sudo tee -a /var/log/sync_profile.log
fi

# Synchronize profile at logout
if [ "$PAM_TYPE" = "close_session" ]; then
    echo "Synchronizing profile at logout for user: $PAM_USER" | sudo tee -a /var/log/sync_profile.log
    rsync -a --delete "$USER_HOME/.config/" "$PROFILE_DIR/.config/" | sudo tee -a /var/log/sync_profile.log
    rsync -a --delete "$USER_HOME/.local/share/" "$PROFILE_DIR/.local/share/" | sudo tee -a /var/log/sync_profile.log
fi
