#!/bin/bash

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

# Update
if (whiptail --title "Update" --yesno "Perform a system update?\n(internet connection required)" 8 33) then
  apt update
  apt upgrade -y
  apt-get autoremove --purge -y
fi