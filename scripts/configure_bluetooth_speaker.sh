#!/bin/bash

# https://bbs.nextthing.co/t/guide-to-connecting-to-a-bluetooth-speaker/4684

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi


if (whiptail --title "Connect a bluetooth device" --yesno "Connect a bluetooth device now?" 15 46) then

if [ $(dpkg-query -W -f='${Status}\n' pulseaudio-module-bluetooth bluez-tools 2>/dev/null | wc -l) -eq 2 ]; then
  echo "pulseaudio-module-bluetooth is already installed!"
  echo "bluez-tools is already installed!"
else
  apt install -y pulseaudio-module-bluetooth bluez-tools
fi

# pulse config
sed -i "s/load-module module-native-protocol-unix.*/load-module module-native-protocol-unix auth-anonymous=1/g" "/etc/pulse/system.pa"

if ! grep -q "### Bluetooth" "/etc/pulse/system.pa"; then
cat <<EOF >> "/etc/pulse/system.pa"

### Bluetooth
load-module module-bluetooth-discover
load-module module-bluetooth-policy
load-module module-switch-on-connect
EOF
fi

cat <<EOF > "/etc/dbus-1/system.d/pulseaudio-bluetooth.conf"
<!-- This configuration file specifies the required security policies for PulseAudio Bluetooth integration. -->
<!DOCTYPE busconfig PUBLIC "-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN" "http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd">
<busconfig>
  <!-- ../system.conf have denied everything, so we just punch some holes -->
  <policy user="pulse">
    <allow own="org.bluez"/>
    <allow send_destination="org.bluez"/>
    <allow send_interface="org.bluez.Agent1"/>
    <allow send_interface="org.bluez.MediaEndpoint1"/>
    <allow send_interface="org.bluez.MediaPlayer1"/>
    <allow send_interface="org.bluez.ThermometerWatcher1"/>
    <allow send_interface="org.bluez.AlertAgent1"/>
    <allow send_interface="org.bluez.Profile1"/>
    <allow send_interface="org.bluez.HeartRateWatcher1"/>
    <allow send_interface="org.bluez.CyclingSpeedWatcher1"/>
    <allow send_interface="org.bluez.GattCharacteristic1"/>
    <allow send_interface="org.bluez.GattDescriptor1"/>
    <allow send_interface="org.freedesktop.DBus.ObjectManager"/>
    <allow send_interface="org.freedesktop.DBus.Properties"/>
  </policy>
  <policy at_console="true">
    <allow send_destination="org.bluez"/>
  </policy>
  <policy context="default">
    <deny send_destination="org.bluez"/>
  </policy>
</busconfig>
EOF

cat <<EOF > /etc/systemd/system/pa.service
[Unit]
Description=PulseAudio Daemon
 
[Service]
Type=simple
PrivateTmp=true
ExecStart=/usr/bin/pulseaudio --system --realtime=false --disallow-exit --high-priority=false

[Install]
WantedBy=multi-user.target
EOF
systemctl enable pa
systemctl restart pa


if which expect >/dev/null; then
  echo "expect is already installed!"
else
  apt install -y expect
fi

cat <<EOF > /usr/bin/speaker
#!/bin/bash

#amixer set "Master" 50%
bt-device --set \$1 Trusted 1

/usr/bin/expect << EOE
spawn bluetoothctl
send "remove \$1\r"
expect -re "Device has been removed|Device \$1 not available"
send "scan on\r"
expect "Discovery started"
expect -re ".*Device \$1\.*"
send "connect \$1\r"
expect "Connection successful"
send "quit\r"
EOE

if which say >/dev/null; then
  say . speaker ready
fi
EOF
chmod +x /usr/bin/speaker

echo "Scanning for Bluetooth devices..."
MACS=`hcitool scan | grep -v "Scanning ..." | sed 's/\s/ /g;s/$/ OFF/g'`
echo "$MACS"
sleep 5
MAC=$(whiptail --title "Connect a bluetooth device" --radiolist "Choose bluetooth device" 20 78 10 `echo "$MACS"` 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then

cat <<EOF > /etc/systemd/system/speaker.service
[Unit]
Description=Connect bluetooth speaker
After=network.target

[Service]
ExecStart=/usr/bin/speaker $MAC
Type=oneshot
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable speaker
systemctl restart speaker

#pactl list short sinks
#pacmd set-default-sink 1

fi

fi
