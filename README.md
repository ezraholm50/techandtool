# Tech and Tool

* Useful graphical tool to install various things and set config values from within the CLI/Terminal
* Initially created for the Nextcloud VM (and RPI ARMHF VM branch) made by @enoch85 and @ezraholm50.
* Tested on Ubuntu server 16.04. (Possibly works on lower versions aswell)
* Might work on other debian distro's aswell.

# How to:
* ```sudo mkdir -p /var/scripts```
* ```sudo wget https://github.com/ezraholm50/techandtool/raw/master/techandtool.sh -P /var/scripts```
* ```sudo cp /var/scripts/techandtool.sh /usr/sbin/techandtool```
* ```chmod +x /usr/sbin/techandtool```
* ```sudo techandtool```
* Every time you want to use the installer run: sudo techandtool

# This script can:
***** Index ******
* 1 Variable / requirements
* 1.1 Network
* 1.2 Raspberry - can get expand
* 1.3 Fix nasty locale error over SSH
* 1.4 Whiptail size
* 1.5 Whiptail check
* 1.6 Root check
* 1.7 Update notification
* 1.8 Locations
* 1.9 Ask to reboot
* 1.10 Vacant
* 2 Apps
* 2.1 Collabora
* 2.2 Spreed-webrtc
* 2.3 Gpxpod
* 2.4 Vacant
* 2.5 Vacant
* 2.6 Vacant
* 3 Tools
* 3.1 Show LAN details
* 3.2 Show WAN details
* 3.3 Change Hostname
* 3.4 Internationalisation
* 3.5 Connect to WLAN
* 3.6 Raspberry specific
* 3.61 Resize root fs
* 3.62 External USB HD
* 3.63 RPI-update
* 3.64 Raspi-config
* 3.7 Show folder size
* 3.8 Show folder content with permissions
* 3.9 Show connected devices
* 3.10 Show disks usage
* 3.11 Show system performance
* 3.12 Disable IPV6
* 3.13 Find string in files
* 3.14 Reboot on out of memory
* 3.15 Vacant
* 3.16 Vacant
* 3.17 Vacant
* 3.18 Vacant
* 3.19 Set dns to google and opendns
* 3.20 Progressbar
* 3.21 Boot terminal
* 3.22 Boot gui
* 3.23 Set swappiness
* 3.24 Delete line containing string
* 3.25 Upgrade kernel
* 3.26 Vacant
* 3.27 Vacant
* 4 Install packages menu
* 4.1 Install packages
* 4.2 Install Webmin
* 4.3 Install SSH server
* 4.4 Install SSH client
* 4.5 Install Change SSH port
* 4.6 Install ClamAV
* 4.7 Install Fail2Ban
* 4.8 Install Nginx
* 4.9 Install Teamspeak
* 4.10 Install NFS client
* 4.11 Install NFS server
* 4.12 Install DDclient
* 4.13 Install Atomic-Toolkit
* 4.14 Install Vacant
* 4.15 Install Network-manager
* 4.16 Install Nextcloud
* 4.17 Install OpenVpn
* 4.18 Install Plex
* 4.19 Install VNC
* 4.20 Install Zram-config
* 4.21 Install Install virtualbox
* 4.22 Install Install virtualbox extension pack
* 4.23 Install Install virtualbox guest additions
* 5 Firewall menu
* 5 Update & upgrade
* 6 About this tool
* 7 Tech and Tool

* CAREFULL THIS IS ALPHA SOFTWARE, USE AT YOUR OWN RISK

# Tech and Me

We at [Tech and Me](https://www.techandme.se) dedicate our time building and maintaining Virtual Machines so that the less skilled users can benefit from easy setup servers.

Here is an example of VM's we offer for **free**:

* Nextcloud / ownCloud
* Nextcloud on a RaspberryPI
* WordPress
* Minecraft
* Access manager
* TeamSpeak

Its as easy as downloading the virtual disk image, mounting it and use it!

For great guides on Linux, ownCloud and Virtual Machines visit [Tech and Me](https://www.techandme.se)
