#!/bin/bash

# CHIP customiser

# must run as ROOT
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

OPTIONS=$(whiptail --title "CHIP customiser v0.1" --checklist --separate-output \
"\nChoose your options, use Spacebar to select multiple options then press Enter." 15 46 6 \
"update.sh" "" OFF \
"first_run.sh" "" OFF \
"install_nginx_router.sh" "" OFF \
"install_pihole.sh" "" OFF \
"install_motioneye.sh" "" OFF \
"install_say.sh" "" OFF \
"install_nodejs.sh" "" OFF \
"install_wetty.sh" "" OFF \
"install_syncthing.sh" "" OFF \
"install_button_menu.sh" "" OFF \
"configure_wifi_ap.sh" "" OFF \
"configure_bluetooth_speaker.sh" "" OFF \
3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]; then
  for OPTION in $OPTIONS; do
    bash <(curl -sL https://rawgit.com/norgeous/CHIP-customiser/master/scripts/$OPTION)
  done
fi
