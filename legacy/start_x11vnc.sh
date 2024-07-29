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