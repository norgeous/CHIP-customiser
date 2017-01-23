#!/bin/bash

# CHIP customiser / first run
# Author: norgeous
# tested with 4.4.13-ntc-mlc headless image

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

OPTIONS=$(whiptail --title "CHIP customiser" --checklist --separate-output \
"Choose your options" 20 78 10 \
"first_run" "Update and change some default settings" OFF \
"say" "Android text to speech engine" OFF \
"bluetooth_speaker" "Add a bluetooth speaker" OFF \
"motioneye" "Remote webcam" OFF \
"pihole" "Adblocker" OFF \
"wifi_ap" "" OFF \
"nodejs" "" OFF \
"wetty" "Remote TTY terminal" OFF \
"button_menu" "Add menu" OFF \
"nginx" "" OFF \
3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
  for OPTION in $OPTIONS; do
    curl -sL "https://raw.githubusercontent.com/norgeous/chip-scripts/master/scripts/$OPTION.sh" | bash -
  done
fi