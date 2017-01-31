#!/bin/bash

# https://bbs.nextthing.co/t/a-few-things-that-a-new-chip-pocketchip-owner-should-do-know-and-try/13803

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# hostname
CURRENTHOST=`hostname`
NEWHOST=$(whiptail --title "Hostname" --inputbox "\nEnter new hostname:" 15 46 $CURRENTHOST 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
  sed -i "s/$CURRENTHOST/$NEWHOST/g" "/etc/hosts"
  sed -i "s/$CURRENTHOST/$NEWHOST/g" "/etc/hostname"
  hostname $NEWHOST
  echo "The new hostname is '$NEWHOST'"
fi

# change 1000 username and set new password
USER1000=`cat /etc/passwd | grep 1000 | cut -d: -f1`
NEWNAME=$(whiptail --title "User" --inputbox "\nEnter new username for UID 1000:" 15 46 $USER1000 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
  usermod -l "$NEWNAME" -d "/home/$NEWNAME" -m "$USER1000"
  USER1000=$NEWNAME
fi

# change 1000 users password
if (whiptail --title "$USER1000 Password" --yesno "Change $USER1000 password?" 15 46) then
  clear
  echo "Enter password for the user '$USER1000':"
  passwd "$USER1000"
fi

# disable root login, other user can still use sudo
if (whiptail --title "Root Password" --yesno "Remove root password?" 15 46) then
  passwd -dl root
fi

# Locale and Timezone
if (whiptail --title "Locale and Timezone" --yesno "Install and configure Locale and Timezones?" 15 46) then
  apt install -y locales
  dpkg-reconfigure locales
  dpkg-reconfigure tzdata
fi

# Reduce swappiness
if (whiptail --title "Swappiness" --yesno "Protect NAND by reducing swappiness to 10?" 15 46) then
  if [ $(cat /etc/sysctl.conf | grep vm.swappiness | wc -l) -eq 0 ]; then
cat <<EOF >> /etc/sysctl.conf
#
# protect NAND by reducing swappiness to 10
vm.swappiness = 10
EOF
  fi
  echo 10 > /proc/sys/vm/swappiness
fi

# Enable ll command
if (whiptail --title "Enable ll command" --yesno "Create global alias for the ll command?" 15 46) then
  if [ $(cat /etc/bash.bashrc | grep "alias ll" | wc -l) -eq 0 ]; then
    echo "alias ll='ls --color=auto -haXl --group-directories-first'" | tee -a /etc/bash.bashrc
  fi
fi
