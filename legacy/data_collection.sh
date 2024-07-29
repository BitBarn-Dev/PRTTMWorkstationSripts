#!/bin/bash

# Define output file
OUTPUT_FILE="dcv_installation_summary.txt"

# Clear output file if it exists
> $OUTPUT_FILE

echo "Collecting system information..."

# System information
echo "### System Information ###" >> $OUTPUT_FILE
echo "OS: $(cat /etc/os-release | grep -w NAME | cut -d '=' -f2)" >> $OUTPUT_FILE
echo "Version: $(cat /etc/os-release | grep -w VERSION | cut -d '=' -f2)" >> $OUTPUT_FILE
echo "Kernel: $(uname -r)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# NVIDIA driver info
echo "### NVIDIA Driver Information ###" >> $OUTPUT_FILE
nvidia-smi --query-gpu=name,driver_version --format=csv,noheader >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

# Check if Nouveau driver is loaded
echo "### Nouveau Driver Check ###" >> $OUTPUT_FILE
if lsmod | grep -q nouveau; then
  echo "Nouveau driver is loaded. Please blacklist it." >> $OUTPUT_FILE
else
  echo "Nouveau driver is not loaded." >> $OUTPUT_FILE
fi
echo "" >> $OUTPUT_FILE

# Check if Secure Boot is enabled
echo "### Secure Boot Status ###" >> $OUTPUT_FILE
if mokutil --sb-state 2>&1 | grep -q "SecureBoot enabled"; then
  echo "Secure Boot is enabled. Consider disabling it for NVIDIA drivers." >> $OUTPUT_FILE
else
  echo "Secure Boot is not enabled." >> $OUTPUT_FILE
fi
echo "" >> $OUTPUT_FILE

# Check GRUB configuration
echo "### GRUB Configuration ###" >> $OUTPUT_FILE
if grep -q 'nouveau' /etc/default/grub; then
  echo "Nouveau driver is blacklisted in GRUB." >> $OUTPUT_FILE
else
  echo "Nouveau driver is not blacklisted in GRUB. Please update the configuration." >> $OUTPUT_FILE
fi
echo "" >> $OUTPUT_FILE

# Check blacklist configuration
echo "### Blacklist Configuration ###" >> $OUTPUT_FILE
if grep -q 'blacklist nouveau' /etc/modprobe.d/blacklist.conf; then
  echo "Nouveau driver is blacklisted in modprobe configuration." >> $OUTPUT_FILE
else
  echo "Nouveau driver is not blacklisted in modprobe configuration. Please update the configuration." >> $OUTPUT_FILE
fi
echo "" >> $OUTPUT_FILE

# Check time synchronization
echo "### Time Synchronization ###" >> $OUTPUT_FILE
timedatectl | grep "NTP synchronized:" >> $OUTPUT_FILE
chronyc tracking | grep -E 'Leap status|Stratum|Ref time|System time' >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

# Active Directory configuration
echo "### AD Configuration ###" >> $OUTPUT_FILE
realm list | grep -E 'domain-name|configured' >> $OUTPUT_FILE 2>&1
echo "" >> $OUTPUT_FILE

# Open ports for AD and DCV
echo "### Open Ports ###" >> $OUTPUT_FILE
firewall-cmd --list-ports | grep -E '8443/tcp|53/tcp|53/udp|88/tcp|88/udp|389/tcp|389/udp|464/tcp|464/udp|3268/tcp' >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Network configuration
echo "### Network Configuration ###" >> $OUTPUT_FILE
nmcli -t -f DEVICE,TYPE,STATE,CON-PATH dev status >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE

# Final message
echo "Data collection complete. The information has been saved to $OUTPUT_FILE."

# Display collected information
cat $OUTPUT_FILE