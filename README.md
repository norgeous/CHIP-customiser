# Chip Customiser
Various bash scripts for CHIP (headless mode) using wiptail

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
first become root:
```
sudo su
```
then download and run the script
```
bash <(curl -sL https://raw.githubusercontent.com/norgeous/chip-scripts/master/RUNME.sh)
```

#### Description of each menu option
###### First run
