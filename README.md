# Chip Customiser
Various bash scripts for CHIP using whiptail menus, tested with 4.4.13-ntc-mlc headless image

#### CHIP flashing Instructions
1. Connect the FEL - GND wire.
2. Flash the CHIP with headless from the Chrome flasher at http://flash.getchip.com/.
3. Power off the CHIP (hold button for 7 seconds).
4. Remove FEL - GND wire.
5. Power on the CHIP (hold button for 1 second).
6. Wait for CHIP to boot.
7. Launch putty and connect to COM port (find with Device Manager).
8. Connect to you home wifi internet with ```nmtui``` or ```nmcli d wifi connect "Netgear" password "12345678" ifname wlan0```
9. Use `ifconfig` to find the CHIP's IP address
10. Exit putty
11. You can now connect to the CHIP over the local network (using putty or `ssh`)

#### Download and run Chip Scripts
Login as `root` with password `chip` and download and run the script with:
```
bash <(curl -sL https://raw.githubusercontent.com/norgeous/chip-scripts/master/RUNME.sh)
```

#### Description of each menu option

##### update
Performs a system update, upgrade and autoremove

##### first_run
Change default hostname, username and password, disable root password, etc.

##### nginx
Port 80 jump off point for other services (lists all open ports). Can be accesed via http://router.admin/

##### wifi_ap
Broadcast wifi ap on wlan1, causes chip to act as router (if wlan0 is connected to the internet).

##### pihole
Network wide adblocker using DNS installed to port 8080. Works well with wifi_ap.

##### motioneye
Cheap CCTV camera.

##### say
install android local tts engine and create wrapper for `say` command.

##### bluetooth_speaker
connect a blutooth speaker and setup a systemd to reconnect it on reboot.
use `systemctl restart speaker` to reconnect speaker manually.

##### nodejs
installs node js 7

##### wetty
installs browser acessable tty through npm and sets a systemd service on port 2222.

##### button_menu
Use chip's built-in button and status led to control chip.
