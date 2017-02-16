#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

if (whiptail --title "Status LED" --yesno "Install statusled command?" 15 46) then

cat <<EOF > /usr/bin/statusled
#!/bin/bash

if [ \$# -eq 0 ]; then
  MODES=\$(cat /sys/class/leds/chip:white:status/trigger | tr -d "\n" | sed 's|\[||;s|\s| x OFF\n|g;s|\]| x ON|;s|ON x OFF|ON|')
  MODE=\$(whiptail --title "Choose" --radiolist "Choose" 20 78 10 \`echo "\$MODES"\` 3>&1 1>&2 2>&3)
  exitstatus=\$?
  if [ \$exitstatus = 0 ]; then

cat <<EOS > /etc/systemd/system/statusled.service
[Unit]
Description=Status LED set mode at startup
After=network.target

[Service]
ExecStart=/usr/bin/statusled \$MODE
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOS

    systemctl enable statusled
    systemctl start statusled

  else
    exit
  fi
else
  MODE=\$1
  echo \$MODE | tee "/sys/class/leds/chip:white:status/trigger"
fi
EOF
chmod +x /usr/bin/statusled

statusled

fi
