#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

if (whiptail --title "WeTTY" --yesno "Install WeTTY?" 15 46) then

if ! which node >/dev/null; then
  echo "nodejs is not installed!"
  bash <(curl -sL "https://rawgit.com/norgeous/CHIP-customiser/master/scripts/install_nodejs.sh")
fi

npm install wetty -g

# Change port from 8384
PORT="2222"
NEWPORT=$(whiptail --title "WeTTY port" --inputbox "\nEnter port number" 15 46 $PORT 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
  PORT="$NEWPORT"
fi

cat <<EOF > /etc/systemd/system/wetty.service
[Unit]
Description=Wetty - Web TTY
After=network.target

[Service]
ExecStart=/usr/bin/wetty -p $PORT

[Install]
WantedBy=multi-user.target
EOF

systemctl enable wetty
systemctl start wetty

fi
