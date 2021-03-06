#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

#clear
#echo "pihole will now install, please use these options:"
#echo
#echo "choose wlan1 from the options"
#echo 
#echo "IP address:    192.168.100.1/24"
#echo "Gateway:       192.168.100.1"
#echo
#read -rsp $'Press any key to continue...\n' -n 1 key
#clear

curl -L https://install.pi-hole.net | bash

sleep 10

# fix piholes dhcpcd
systemctl start dhcpcd
sed -i 's|  static ip_address=.*||g' /etc/dhcpcd.conf
sed -i 's|  static routers=.*||g' /etc/dhcpcd.conf
sed -i 's|  static domain_name_servers=.*||g' /etc/dhcpcd.conf

# change lighthttp port from 80 to 8080
NEWPORT=$(whiptail --title "PiHole lighttpd port" --inputbox "\nEnter port number" 15 46 "8080" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
  sed -i 's/server\.port.*/server.port = $NEWPORT/g' /etc/lighttpd/lighttpd.conf
fi

# restart services
systemctl restart networking dhcpcd dnsmasq lighttpd
echo "you may need to reboot!"
