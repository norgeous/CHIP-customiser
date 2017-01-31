#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi


if (whiptail --title "WIFI AP" --yesno "Configure options of WIFI AP?" 15 46) then

# wlan1 ap settings
SSID="BTWifi-base"
PASS="12345678"
NETWORK="192.168.100"  # 192.168.100.x

# User provides settings
SSID=$(whiptail --title "Wifi SSID" --inputbox "Enter Wifi AP SSID" --nocancel 8 78 $SSID 3>&1 1>&2 2>&3)
PASS=$(whiptail --title "Wifi Password" --inputbox "Enter Wifi password" --nocancel 8 78 $PASS 3>&1 1>&2 2>&3)
NETWORK=$(whiptail --title "Network Range" --inputbox "Enter Wifi network range (first 3 octets only)" --nocancel 8 78 $NETWORK 3>&1 1>&2 2>&3)

# wlan1 config
cat <<EOF > /etc/network/interfaces.d/wlan1
auto wlan1
allow-hotplug wlan1
iface wlan1 inet static
  hostapd /etc/hostapd.conf
  address $NETWORK.1
  netmask 255.255.255.0
  network $NETWORK.0
  broadcast $NETWORK.255
EOF

# hostapd config for wlan1
cat <<EOF > /etc/hostapd.conf
interface=wlan1
driver=nl80211
hw_mode=g
channel=1
ieee80211n=1
ieee80211d=1
ieee80211h=1
wmm_enabled=1
ht_capab=[HT40][SHORT-GI-20][DSSS_CCK-40]
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP CCMP
rsn_pairwise=CCMP
country_code=GB
ssid=$SSID
wpa_passphrase=$PASS
max_num_sta=10
ctrl_interface=/var/run/hostapd
EOF

# dnsmasq config
apt install -y dnsmasq
cat <<EOF > /etc/dnsmasq.d/access_point.conf
interface=wlan1
except-interface=wlan0
dhcp-range=$NETWORK.2,$NETWORK.255,1h
addn-hosts=/etc/dnsmasq_static_hosts.conf
EOF

# dnsmasq hosts (exposes http://router.admin)
cat <<EOF > /etc/dnsmasq_static_hosts.conf
$NETWORK.1 router.admin
EOF

# enable ip4 nat forwarding
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf

# iptables routing rules
iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o wlan1 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i wlan1 -o wlan0 -j ACCEPT
sh -c "iptables-save > /etc/iptables.ipv4.nat"
mkdir -p /lib/dhcpcd/dhcpcd-hooks
echo 'iptables-restore < /etc/iptables.ipv4.nat' | sudo tee /lib/dhcpcd/dhcpcd-hooks/70-ipv4-nat

# restart networking to apply settings
systemctl restart networking dhcpcd dnsmasq
echo "you may need to reboot!"

fi
