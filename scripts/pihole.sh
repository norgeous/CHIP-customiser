#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

clear
echo "pihole will now install, please use these options:"
echo
echo "choose wlan1 from the options"
echo 
echo "IP address:    192.168.100.1/24"
echo "Gateway:       192.168.100.1"
echo
read -rsp $'Press any key to continue...\n' -n 1 key
clear

curl -L https://install.pi-hole.net | bash
#curl -L https://raw.githubusercontent.com/pi-hole/pi-hole/739aaafa9a7cf90fb0ab58af0f873b7cc8aec1f5/automated%20install/basic-install.sh | bash # Pi-hole v2.10.2

sleep 10

# fix piholes dhcpcd
systemctl start dhcpcd
sed -i 's|\<  static ip_address=192.168.100.1/24\>|#  static ip_address=192.168.100.1/24|g' /etc/dhcpcd.conf
sed -i 's|\<  static routers=192.168.100.1\>|#  static routers=192.168.100.1|g' /etc/dhcpcd.conf
sed -i 's|\<  static domain_name_servers=192.168.100.1\>|#  static domain_name_servers=192.168.100.1|g' /etc/dhcpcd.conf
systemctl restart dhcpcd

# change lighthttp port from 80 to 8080
sed -i 's/\<server.port                 = 80\>/server.port                 = 8080/g' /etc/lighttpd/lighttpd.conf
systemctl restart lighttpd
