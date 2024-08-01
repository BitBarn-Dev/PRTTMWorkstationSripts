#!/bin/bash

# File to track the latest completed step
STEP_FILE="/var/tmp/latest_step"

# Read the latest completed step
if [ -f "$STEP_FILE" ]; then
  latest_step=$(cat "$STEP_FILE")
else
  latest_step=0
fi

# Function to update the latest completed step and ask for reboot
update_step() {
  echo $1 > "$STEP_FILE"
  echo "Step $1 completed. Do you want to reboot now or continue? (r/c)"
  read -r answer
  if [ "$answer" == "r" ]; then
    sudo reboot
  fi
}

case $latest_step in

  0)
    ###################################################
    # Step 1: Update the OS with latest patches
    echo "Updating the OS with the latest patches..."
    sudo yum upgrade -y
    update_step 1
    ;;

  1)
    ###################################################
    # Step 2: Configuration and initial setup
    echo "Performing configuration and initial setup..."

    # Check if on AWS
    aws_cfg="NO"

    sudo yum groupinstall 'Server with GUI' -y
    sudo systemctl get-default
    sudo systemctl set-default graphical.target
    sudo systemctl isolate graphical.target
    ps aux | grep X | grep -v grep

    sudo yum install glx-utils -y

    sudo DISPLAY=:0 XAUTHORITY=$(ps aux | grep "X.*\-auth" | grep -v grep \
          | sed -n 's/.*-auth \([^ ]\+\).*/\1/p') glxinfo | grep -i "opengl.*version"

    sudo yum erase nvidia cuda

    sudo yum install -y make gcc kernel-devel-$(uname -r) wget
    cat << EOF | sudo tee --append /etc/modprobe.d/blacklist.conf
blacklist vga16fb
blacklist nouveau
blacklist rivafb
blacklist nvidiafb
blacklist rivatv
EOF

    echo 'GRUB_CMDLINE_LINUX="rdblacklist=nouveau"' | sudo tee -a /etc/default/grub > /dev/null
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    echo "Configuration and initial setup completed. A reboot is required to remove the nouveau driver."
    update_step 2
    ;;

  2)
    ###################################################
    # Step 3: Install NVIDIA drivers and DCV
    echo "Installing NVIDIA drivers and DCV..."

    sudo yum install elfutils-libelf-devel elfutils-devel -y
    wget https://us.download.nvidia.com/tesla/515.48.07/NVIDIA-Linux-x86_64-515.48.07.run
    sudo systemctl isolate multi-user.target   # which will log you out probably
    sudo /bin/sh ./NVIDIA-Linux-x86_64*.run -s

    nvidia-smi -q | head

    sudo nvidia-xconfig --preserve-busid --enable-all-gpus

    dcv_version="2023"
    echo Checking for latest DCV $dcv_version version
    dcv_server=$(curl --silent --output - https://download.nice-dcv.com/ | \
        grep href | egrep "$dcv_version" | grep "el8" | grep Server | sed -e 's/.*http/http/' -e 's/tgz.*/tgz/' | head -1)
    echo "We will be downloading DCV server from $dcv_server"
    sudo rpm --import https://d1uj6qtbmh3dt5.cloudfront.net/NICE-GPG-KEY
    echo Downloading DCV Server from $dcv_server
    wget $dcv_server

    tar zxvf nice-dcv-*el8*.tgz
    cd nice-dcv-*x86_64
    sudo yum install nice-dcv-server-*.el8.x86_64.rpm \
         nice-xdcv-*.el8.x86_64.rpm nice-dcv-gl-*.el8.x86_64.rpm \
         nice-dcv-web-viewer*.el8.x86_64.rpm  \
         nice-dcv-gltest-*.el8.x86_64.rpm nice-dcv-simple-external-authenticator-*.el8.x86_64.rpm -y

    sudo systemctl isolate multi-user.target
    sudo systemctl isolate graphical.target

    sudo DISPLAY=:0 XAUTHORITY=$(ps aux | grep "X.*\-auth" | \
       grep -v grep | sed -n 's/.*-auth \([^ ]\+\).*/\1/p') glxinfo | grep -i "opengl.*version"

    sudo dcvgladmin enable
    sudo firewall-cmd --zone=public --add-port=8443/tcp --permanent
    sudo firewall-cmd --reload
    sudo firewall-cmd --list-all
    sudo iptables-save | grep 8443
    cd /etc/dcv/
    sudo openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365
    sudo echo 'ca-file="/etc/dcv/cert.pem"' >> /etc/dcv/dcv.conf
    sudo systemctl enable dcvserver
    sudo systemctl start dcvserver

    update_step 3
    ;;

  3)
    ###################################################
    # Step 4: Install dvc.conf and restart DCV service
    echo "Installing dvc.conf and restarting DCV service..."

    # Define the configuration content
    CONFIG_CONTENT='[license]

[log]

[session-management]
create-session = true

[session-management/defaults]

[session-management/automatic-console-session]

[display]
target-fps=60

[connectivity]
enable-quic-frontend=true
enable-datagrams-display = always-off
idle-timeout=20
idle-timeout-warning=600
disconnect-on-logout=true
max-target-bitrate=60000

[security]
authentication="system"
    '

    # Define the destination path
    CONFIG_PATH="/etc/dvc/dvc.conf"

    # Create the directory if it doesn't exist
    sudo mkdir -p "$(dirname "$CONFIG_PATH")"

    # Write the configuration content to the file
    echo "$CONFIG_CONTENT" | sudo tee "$CONFIG_PATH" > /dev/null

    # Set the appropriate permissions
    sudo chmod 644 "$CONFIG_PATH"

    # Restart the DCV service
    sudo systemctl restart dcvserver

    echo "dvc.conf has been installed and the DCV service has been restarted."
    update_step 4
    ;;

  *)
    echo "All steps are completed. Exiting."
    ;;
esac