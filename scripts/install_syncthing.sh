#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi


if (whiptail --title "Syncthing" --yesno "Install Syncthing?" 15 46) then

# Add Syncthing repo
curl -s https://syncthing.net/release-key.txt | apt-key add -
echo "deb http://apt.syncthing.net/ syncthing release" | tee /etc/apt/sources.list.d/syncthing.list

# Update and Install
apt update
apt install -y syncthing

# Syncthing config file
syncthing -generate="/root/.config/syncthing/"

# Open Syncthing to remote access
sed -i 's/127.0.0.1/0.0.0.0/g' /root/.config/syncthing/config.xml

# Configure Syncthing service
cat <<EOF > /etc/systemd/system/syncthing.service
[Unit]
Description=Syncthing - Open Source Continuous File Synchronization
Documentation=man:syncthing(1)
After=network.target
Wants=syncthing-inotify@.service

[Service]
User=root
ExecStart=/usr/bin/syncthing -no-browser -no-restart -logflags=0
Restart=on-failure
SuccessExitStatus=3 4
RestartForceExitStatus=3 4

[Install]
WantedBy=multi-user.target
EOF

# Enable and start Syncthing
systemctl enable syncthing
systemctl start syncthing

fi
