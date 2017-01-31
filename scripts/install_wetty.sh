#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi


if (whiptail --title "WeTTY" --yesno "Install WeTTY?" 15 46) then

if ! which node >/dev/null; then
  echo "nodejs is not installed!"
else

npm install wetty -g

cat <<EOF > /etc/systemd/system/wetty.service
[Unit]
Description=Wetty - Web TTY
After=network.target

[Service]
ExecStart=/usr/bin/wetty -p 2222

[Install]
WantedBy=multi-user.target
EOF

systemctl enable wetty
systemctl start wetty

fi

fi
