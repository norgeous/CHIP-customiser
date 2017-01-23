#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

npm install wetty -g

cat <<EOF > /etc/systemd/system/wetty.service
[Unit]
Description=Wetty - Web TTY
After=network.target

[Service]
ExecStart=/usr/bin/wetty -p 3000

[Install]
WantedBy=multi-user.target
EOF

systemctl enable wetty
systemctl start wetty
