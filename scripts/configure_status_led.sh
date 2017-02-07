#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

if (whiptail --title "Status LED" --yesno "Disable status LED blinking?" 15 46) then

cat <<EOF > /usr/bin/statusled
#!/bin/bash
case \$1 in
  on)
    echo none kbd-scrollock kbd-numlock kbd-capslock kbd-kanalock kbd-shiftlock kbd-altgrlock kbd-ctrllock kbd-altlock kbd-shiftllock kbd-shiftrlock kbd-ctrlllock kbd-ctrlrlock nand-disk usb-gadget usb-host axp20x-usb-online timer oneshot [heartbeat] backlight gpio cpu0 default-on transient flash torch mmc0 rfkill0 rfkill1 rfkill2 | tee "/sys/class/leds/chip:white:status/trigger"
  off)
    echo none | tee "/sys/class/leds/chip:white:status/trigger"
EOF
chmod +x /usr/bin/statusled

cat <<EOF > /etc/systemd/system/statusled.service
[Unit]
Description=Status LED control
After=network.target

[Service]
ExecStart=/usr/bin/statusled off
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable statusled
systemctl start statusled

fi
