#!/bin/bash
#
# Tech and Me, 2016 - www.techandme.se
# Whiptail menu to install various Nextcloud app and do other useful stuf.
##### Index ######
# 1 Variable
# 1.1 Network
# 1.2 Raspberry - can get expand
# 1.3
# 1.4 Whiptail size
# 1.5 Whiptail check
# 1.6 Root check
# 1.7
# 1.8 Locations
# 1.9 Ask to reboot
# 1.10
# 2 Apps
# 2.1 Collabora
# 2.2 Spreed-webrtc
# 2.3 Gpxpod
# 2.4
# 2.5
# 2.6
# 3 Tools
# 3.1 Show LAN details
# 3.2 Show WAN details
# 3.3 Change Hostname
# 3.4 Internationalisation
# 3.5 Connect to WLAN
# 3.6 Raspberry specific
# 3.61 Resize root fs
# 3.62 External USB HD
# 3.63 RPI-update
# 3.64 Raspi-config
# 3.7 Show folder size
# 3.8 Show folder content with permissions
# 3.9 Show connected devices
# 3.10 Show disks usage
# 3.11 Show system performance
# 3.12 Disable IPV6
# 3.13 Find string in files
# 3.14 Reboot on out of memory
# 3.15
# 3.16
# 3.17
# 3.18
# 3.19 Set dns to google and opendns
# 3.20 Progressbar
# 3.21 Boot terminal
# 3.22 Boot gui
# 3.23 Set swappiness
# 3.24 Delete line containing string
# 3.25 Upgrade kernel
# 3.26
# 3.27
# 4 Install packages menu
# 4.1 Install packages
# 4.2 Install Webmin
# 4.3 Install SSH server
# 4.4 Install SSH client
# 4.5 Install Change SSH port
# 4.6 Install ClamAV
# 4.7 Install Fail2Ban
# 4.8 Install Nginx
# 4.9 Install Teamspeak
# 4.10 Install NFS client
# 4.11 Install NFS server
# 4.12 Install DDclient
# 4.13 Install Atomic-Toolkit
# 4.14 Install
# 4.15 Install Network-manager
# 4.16 Install Nextcloud
# 4.17 Install OpenVpn
# 4.18 Install Plex
# 4.19 Install VNC
# 4.20 Install Zram-config
# 4.21 Install Install virtualbox
# 4.22 Install Install virtualbox extension pack
# 4.23 Install Install virtualbox guest additions
# 5 Firewall menu
# 5 Update & upgrade
# 6 About this tool
# 7 Tech and Tool

################################################ Variable 1
################################ Network 1.1

IFCONFIG=$(ifconfig)
IP="/sbin/ip"
IFACE=$($IP -o link show | awk '{print $2,$9}' | grep "UP" | cut -d ":" -f 1)
INTERFACES="/etc/network/interfaces"
ADDRESS=$($IP route get 1 | awk '{print $NF;exit}')
NETMASK=$(ifconfig "$IFACE" | grep Mask | sed s/^.*Mask://)
GATEWAY=$($IP route | awk '/default/ { print $3 }')

################################ Raspberry - can get expand 1.2

get_can_expand() {
  get_init_sys
  if [ $SYSTEMD -eq 1 ]; then
    ROOT_PART=$(mount | sed -n 's|^/dev/\(.*\) on / .*|\1|p')
  else
    if ! [ -h /dev/root ]; then
      echo 1
      exit
    fi
    ROOT_PART=$(readlink /dev/root)
  fi

  PART_NUM=${ROOT_PART#mmcblk0p}
  if [ "$PART_NUM" = "$ROOT_PART" ]; then
    echo 1
    exit
  fi

  if [ "$PART_NUM" -ne 2 ]; then
    echo 1
    exit
  fi

  LAST_PART_NUM=$(parted /dev/mmcblk0 -ms unit s p | tail -n 1 | cut -f 1 -d:)
  if [ $LAST_PART_NUM -ne $PART_NUM ]; then
    echo 1
    exit
  fi
  echo 0
}

################################ 1.3



################################ Whiptail size 1.4

INTERACTIVE=True
calc_wt_size() {
  WT_HEIGHT=17
  WT_WIDTH=$(tput cols)

  if [ -z "$WT_WIDTH" ] || [ "$WT_WIDTH" -lt 60 ]; then
    WT_WIDTH=80
  fi
  if [ "$WT_WIDTH" -gt 178 ]; then
    WT_WIDTH=120
  fi
  WT_MENU_HEIGHT=$((WT_HEIGHT-7))
}

################################################ Whiptail check 1.5

	if [ $(dpkg-query -W -f='${Status}' whiptail 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        sleep 0

else

    {
    i=1
    while read -r line; do
        i=$(( i + 1 ))
        echo $i
    done < <(apt-get install whiptail -y)
  } | whiptail --title "Progress" --gauge "Please wait while installing Whiptail..." $WT_HEIGHT $WT_WIDTH

fi

################################################ Check if root 1.6

if [ "$(whoami)" != "root" ]; then
        whiptail --msgbox "Sorry you are not root. You must type: sudo techandtool" $WT_HEIGHT $WT_WIDTH
        exit
fi

################################################ 1.7



################################################ Locations 1.8

REPO="https://github.com/ezraholm50/vm/raw/master"
SCRIPTS="/var/scripts"

################################################ Do finish 1.9

ASK_TO_REBOOT=0
do_finish() {
  if [ $ASK_TO_REBOOT -eq 1 ]; then
    whiptail --yesno "Would you like to reboot now?" 20 60 2
    if [ $? -eq 0 ]; then # yes
      sync
      reboot
    fi
  fi
  exit 0
}

################################################ 1.10



################################################ Apps 2

do_apps() {
  FUN=$(whiptail --backtitle "Apps" --title "Tech and Tool - https://www.techandme.se" --menu "Tech and tool" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
  "P1 Collabora" "Docker" \
  "P2 Spreed-webrtc" "Spreedme" \
  "P3 Gpxpod" ""\
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      P1\ *) do_collabora ;;
      P2\ *) do_spreed_webrtc ;;
      P3\ *) do_gpxpod ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
 else
   exit 1
  fi
}

################################ Collabora 2.1

do_collabora() {
  whiptail --msgbox "Under construction..." $WT_HEIGHT $WT_WIDTH
}

################################ Spreed-webrtc 2.2

do_spreed_webrtc() {
ENCRYPTIONSECRET=$(openssl rand -hex 32)
SESSIONSECRET=$(openssl rand -hex 32)
SERVERTOKEN=$(openssl rand -hex 32)
SHAREDSECRET=$(openssl rand -hex 32)
DOMAIN=$(whiptail --title "Techandme.se Collabora online installer" --inputbox "Nextcloud url, make sure it looks like this: https://cloud.nextcloud.com" $WT_HEIGHT $WT_WIDTH https://yourdomain.com 3>&1 1>&2 2>&3)
NCDIR=$(whiptail --title "Nextcloud directory" --inputbox "If you're not sure use the default setting" $WT_HEIGHT $WT_WIDTH /var/www/nextcloud 3>&1 1>&2 2>&3)
WEB=$(whiptail --title "What webserver do you run" --inputbox "If you're not sure use the default setting" $WT_HEIGHT $WT_WIDTH apache2 3>&1 1>&2 2>&3)
SPREEDDOMAIN=$(whiptail --title "Spreed domain" --inputbox "Leave empty for autodiscovery" $WT_HEIGHT $WT_WIDTH 3>&1 1>&2 2>&3)
SPREEDPORT=$(whiptail --title "Spreed port" --inputbox "If you're not sure use the default setting" $WT_HEIGHT $WT_WIDTH 8443 3>&1 1>&2 2>&3)
VHOST443=$(whiptail --title "Vhost 443 file location" --inputbox "If you're not sure use the default setting" $WT_HEIGHT $WT_WIDTH /etc/"$WEB"/sites-available/nextcloud_ssl_domain_self_signed.conf 3>&1 1>&2 2>&3)
#VHOST80="/etc/$WEB/sites-available/xxx"
LISTENADDRESS="$ADDRESS"
LISTENPORT="$SPREEDPORT"

# Install spreed (Unstable is used as there are some systemd errors in ubuntu 16.04)
apt-add-repository ppa:strukturag/spreed-webrtc
apt-get update
apt-get install spreed-webrtc -y

# Change server conf.
sed -i "s|listen = 127.0.0.1:8080|listen = $LISTENADDRESS:$LISTENPORT|g" /etc/spreed/webrtc.conf
sed -i "s|;basePath = /some/sub/path/|basePath = /webrtc/|g" /etc/spreed/webrtc.conf
sed -i "s|;authorizeRoomJoin = false|authorizeRoomJoin = true|g" /etc/spreed/webrtc.conf
sed -i "s|;stunURIs = stun:stun.spreed.me:443|stunURIs = stun:stun.spreed.me:443|g" /etc/spreed/webrtc.conf
sed -i "s|encryptionSecret = .*|encryptionSecret = $ENCRYPTIONSECRET|g" /etc/spreed/webrtc.conf
sed -i "s|sessionSecret = .*|sessionSecret = $SESSIONSECRET|g" /etc/spreed/webrtc.conf
sed -i "s|serverToken = .*|serverToken = $SERVERTOKEN|g" /etc/spreed/webrtc.conf
sed -i "s|;extra = /usr/share/spreed-webrtc-server/extra|extra = $NCDIR/apps/spreedme/extra|g" /etc/spreed/webrtc.conf
sed -i "s|;plugin = extra/static/myplugin.js|plugin = $NCDIR/apps/spreedme/extra/static/owncloud.js|g" /etc/spreed/webrtc.conf
sed -i "s|enabled = false|enabled = true|g" /etc/spreed/webrtc.conf
sed -i "s|;mode = sharedsecret|mode = sharedsecret|g" /etc/spreed/webrtc.conf
sed -i "s|;sharedsecret_secret = .*|sharedsecret_secret = $SHAREDSECRET|g" /etc/spreed/webrtc.conf

# Change spreed.me config.php
cp "$NCDIR"/apps/spreedme/config/config.php.in "$NCDIR"/apps/spreedme/config/config.php
sed -i "s|const SPREED_WEBRTC_ORIGIN = '';|const SPREED_WEBRTC_ORIGIN = '$SPREEDDOMAIN';|g" "$NCDIR"/apps/spreedme/config/config.php
sed -i "s|const SPREED_WEBRTC_SHAREDSECRET = 'bb04fb058e2d7fd19c5bdaa129e7883195f73a9c49414a7eXXXXXXXXXXXXXXXX';|const SPREED_WEBRTC_SHAREDSECRET = '$SHAREDSECRET';|g" "$NCDIR"/apps/spreedme/config/config.php

# Change OwnCloudConfig.js
cp "$NCDIR"/apps/spreedme/extra/static/config/OwnCloudConfig.js.in "$NCDIR"/apps/spreedme/extra/static/config/OwnCloudConfig.js
sed -i "s|OWNCLOUD_ORIGIN: '',|OWNCLOUD_ORIGIN: 'SPREEDDOMAIN',|g" "$NCDIR"/apps/spreedme/extra/static/config/OwnCloudConfig.js

# Restart spreed server
service spreedwebrtc restart

# Vhost configuration 443
sed -i 's|</VirtualHost>||g' "$VHOST443"
CAT <<-VHOST > "$VHOST443"
<Location /webrtc>
      ProxyPass http://"$LISTENADDRESS":"$LISTENPORT"/webrtc
      ProxyPassReverse /webrtc
  </Location>
  <Location /webrtc/ws>
      ProxyPass ws://"$LISTENADDRESS":"$LISTENPORT"/webrtc/ws
  </Location>
  ProxyVia On
  ProxyPreserveHost On
  RequestHeader set X-Forwarded-Proto 'https' env=HTTPS
</VirtualHost>
VHOST

# Enable apache2 mods if needed
      	if [ -d /etc/apache2/ ]; then
      	        a2enmod proxy proxy_http proxy_wstunnel headers
      	fi

# Restart webserver
service "$WEB" reload

# Almost done
echo
echo "Please enable the app in Nextcloud/ownCloud..."
echo
echo "If there are any errors make sure to append /?debug to the url when visiting the spreedme app in the cloud"
echo "This will help us troubleshoot the issues, you could also visit: mydomain.com/index.php/apps/spreedme/admin/debug"
}

################################ Gpxpod 2.3

do_gpxpod() {
	sleep 1
}

################################################ Tools 3

do_tools() {
FUN=$(whiptail --backtitle "Tools" --title "Tech and Tool - Tools - https://www.techandme.se" --menu "Tech and tool" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
"T1 Show LAN IP, Gateway, Netmask" "Ifconfig" \
"T2 Show WAN IP" "External IP address" \
"T3 Change Hostname" "Your machine's name" \
"T4 Internationalisation Options" "Change language, time, date and keyboard layout" \
"T5 Connect to WLAN" "Please have a wifi dongle/card plugged in before start" \
"T6 Show folder size" "Using ncdu" \
"T7 Show folder content" "with permissions" \
"T8 Show connected devices" "blkid" \
"T9 Show disks usage" "df -h" \
"T10 Show system performance" "HTOP" \
"T11 Disable IPV6" "Via sysctl.conf" \
"T12 Find text" "In a given directory" \
"T13 OOM fix" "Auto reboot on out of memory errors" \
"T18 Set dns to Google and OpenDns" "Try google first if no response after 1 sec. switch to next NS" \
"T19 Add progress bar" "Apply's to apt-get update, install & upgrade" \
"T20 Boot to terminal by default" "Only if you use a GUI/desktop now" \
"T21 Boot to GUI/desktop by default" "Only if you have a GUI installed and have terminal as default" \
"T22 Delete line containing a string of text" "Warning, deletes every line containing the string!" \
"T23 Set swappiness" "" \
"T24 Upgrade Ubuntu Kernel" "To the latest version" \
"T25 Backup your system" "" \
"T26 Restore backup" "Made with the option above" \
"T27 Protect SSH with Fail2Ban" "" \
"T28 Protect SSH with Google 2 factor authentication" "" \
"T29 Distribution upgrade" "Only LTS" \
  3>&1 1>&2 2>&3)
RET=$?
if [ $RET -eq 1 ]; then
  return 0
elif [ $RET -eq 0 ]; then
  case "$FUN" in
    T1\ *) do_ifconfig ;;
    T2\ *) do_wan_ip ;;
    T3\ *) do_change_hostname ;;
    T4\ *) do_internationalisation_menu ;;
    T5\ *) do_wlan ;;
    T6\ *) do_foldersize ;;
    T7\ *) do_listdir ;;
    T8\ *) do_blkid ;;
    T9\ *) do_df ;;
    T10\ *) do_htop ;;
    T11\ *) do_disable_ipv6 ;;
    T12\ *) do_find_string ;;
    T13\ *) do_oom ;;
    T18\ *) do_dns ;;
    T19\ *) do_progressbar ;;
    T20\ *) do_bootterminal ;;
    T21\ *) do_bootgui ;;
    T22\ *) do_stringdel ;;
    T23\ *) do_swappiness ;;
    T24\ *) do_ukupgrade ;;
    T25\ *) do_backup ;;
    T26\ *) do_restore_backup ;;
    T27\ *) do_fail2ban_ssh ;;
    T28\ *) do_2fa ;;
    T29\ *) do_ltsupgrade ;;
    *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
  esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
else
 exit 1
fi
}

################################ Network details 3.1

do_ifconfig() {
whiptail --msgbox "\
Interface: $IFACE
LAN IP: $ADDRESS
Netmask: $NETMASK
Gateway: $GATEWAY\
" $WT_HEIGHT $WT_WIDTH
}

################################ Wan IP 3.2

do_wan_ip() {
  WAN=$(wget -qO- http://ipecho.net/plain ; echo)
  whiptail --msgbox "WAN IP: $WAN" $WT_HEIGHT $WT_WIDTH
}

################################ Hostname 3.3

do_change_hostname() {
  whiptail --msgbox "\
Please note: RFCs mandate that a hostname's labels \
may contain only the ASCII letters 'a' through 'z' (case-insensitive),
the digits '0' through '9', and the hyphen.
Hostname labels cannot begin or end with a hyphen.
No other symbols, punctuation characters, or blank spaces are permitted.\
" $WT_HEIGHT $WT_WIDTH

  CURRENT_HOSTNAME=$(cat < /etc/hostname | tr -d " \t\n\r")
  NEW_HOSTNAME=$(whiptail --inputbox "Please enter a hostname" 20 60 "$CURRENT_HOSTNAME" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    echo "$NEW_HOSTNAME" > /etc/hostname
    sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
  fi
}

################################ Internationalisation 3.4

do_internationalisation_menu() {
  FUN=$(whiptail --backtitle "Internationalisation" --title "Tech and Tool - https://www.techandme.se" --menu "Internationalisation Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "I1 Change Locale" "Set up language and regional settings to match your location" \
    "I2 Change Timezone" "Set up timezone to match your location" \
    "I3 Change Keyboard Layout" "Set the keyboard layout to match your keyboard" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      I1\ *) do_change_locale ;;
      I2\ *) do_change_timezone ;;
      I3\ *) do_configure_keyboard ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

######

do_configure_keyboard() {
  dpkg-reconfigure keyboard-configuration &&
  printf "Reloading keymap. This may take a short while\n" &&
  invoke-rc.d keyboard-setup start
}

######

do_change_locale() {
  dpkg-reconfigure locales
}

######

do_change_timezone() {
  dpkg-reconfigure tzdata
}

################################ Wifi 3.5
#IFACEWIFI=$(lshw -c network | grep "wl" | awk '{print $3}')
#IFACEWIRED=$(lshw -c network | grep "en" | awk '{print $3}')

do_wlan() {
whiptail --yesno "Do you want to connect to wifi? Its recommended to use a wired connection for your Nextcloud server!" --yes-button "Wireless" --no-button "Wired" 20 60 1
	if [ $? -eq 0 ];         then # yes

                        apt-get install linux-firmware wicd-curses wicd-daemon wicd-cli -y
                        #ifdown "$IFACEWIRED"
                        #sed -i "s|'$IFACEWIRED'|'$IFACEWIFI'|g" /etc/network/interfaces
			whiptail --msgbox "In the next screen navigate with the arrow keys (right arrow for config) and don't for get to select auto connect at the networks config settings." 20 60 2
                        wicd-curses
                        #ifup "$IFACEWIFI"
                        whiptail --msgbox "Due to the new interface the DHCP server gave you a new ip:\n\n'$ADDRESS' \n\n If the NIC starts with 'wl', you're good to go and you can unplug the ethernet cable: \n\n '$IFACE'" 12 60 1

	else
        		echo
        		echo "We'll use a wired connection..."
        		echo
fi
}

################################ Raspberry specific 3.6

do_Raspberry() {
  FUN=$(whiptail --backtitle "Raspberry" --title "Tech and Tool - https://www.techandme.se" --menu "Raspberry" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
  "R1 Resize SD" "" \
  "R2 External USB" "Use an USB HD/SSD as root" \
  "R3 RPI-update" "Update the RPI firmware and kernel" \
  "R4 Raspi-config" "Set various settings, not all are tested! Already safely overclocked!" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      R1\ *) do_expand_rootfs "$@";;
      R2\ *) do_external_usb ;;
      R3\ *) do_rpi_update ;;
      R4\ *) do_raspi_config ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

##################### Resize SD 3.61

do_expand_rootfs() {
  if ! [ -h /dev/root ]; then
    whiptail --msgbox "/dev/root does not exist or is not a symlink. Don't know how to expand" 20 60 2
    return 0
  fi

  ROOT_PART=$(readlink /dev/root)
  PART_NUM=${ROOT_PART#mmcblk0p}
  if [ "$PART_NUM" = "$ROOT_PART" ]; then
    whiptail --msgbox "/dev/root is not an SD card. Don't know how to expand" 20 60 2
    return 0
  fi

  # NOTE: the NOOBS partition layout confuses parted. For now, let's only
  # agree to work with a sufficiently simple partition layout
  if [ "$PART_NUM" -ne 2 ]; then
    whiptail --msgbox "Your partition layout is not currently supported by this tool. You are probably using NOOBS, in which case your root filesystem is already expanded anyway." 20 60 2
    return 0
  fi

  LAST_PART_NUM=$(parted /dev/mmcblk0 -ms unit s p | tail -n 1 | cut -f 1 -d:)

  if [ "$LAST_PART_NUM" != "$PART_NUM" ]; then
    whiptail --msgbox "/dev/root is not the last partition. Don't know how to expand" 20 60 2
    return 0
  fi

  # Get the starting offset of the root partition
  PART_START=$(parted /dev/mmcblk0 -ms unit s p | grep "^${PART_NUM}" | cut -f 2 -d:)
  [ "$PART_START" ] || return 1
  # Return value will likely be error for fdisk as it fails to reload the
  # partition table because the root fs is mounted
  fdisk /dev/mmcblk0 <<EOF
p
d
$PART_NUM
n
p
$PART_NUM
$PART_START
p
w
EOF

  # now set up an init.d script
cat <<\EOF > /etc/init.d/resize2fs_once &&
#!/bin/sh
### BEGIN INIT INFO
# Provides:          resize2fs_once
# Required-Start:
# Required-Stop:
# Default-Start: 2 3 4 5 S
# Default-Stop:
# Short-Description: Resize the root filesystem to fill partition
# Description:
### END INIT INFO
. /lib/lsb/init-functions
case "$1" in
  start)
    log_daemon_msg "Starting resize2fs_once" &&
    resize2fs /dev/root &&
    rm /etc/init.d/resize2fs_once &&
    update-rc.d resize2fs_once remove &&
    log_end_msg $?
    ;;
  *)
    echo "Usage: $0 start" >&2
    exit 3
    ;;
esac
EOF
  chmod +x /etc/init.d/resize2fs_once &&
  update-rc.d resize2fs_once defaults &&

  whiptail --msgbox "Root partition has been resized.\nThe filesystem will be enlarged upon the next reboot" $WT_HEIGHT $WT_WIDTH
  ASK_TO_REBOOT=1
}

##################### External USB 3.62

do_external_usb() {
	whiptail --msgbox "This option will be added soon!" $WT_HEIGHT $WT_WIDTH
}

##################### RPI-update 3.63

do_rpi_update() {
  if [ $(dpkg-query -W -f='${Status}' rpi-update 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    {
    i=1
    while read -r line; do
        i=$(( i + 1 ))
        echo $i
    done < <(rpi-update)
    } | whiptail --title "Progress" --gauge "Please wait while updating your RPI firmware and kernel" $WT_HEIGHT $WT_WIDTH
else
    apt-get install rpi-update -y

	  {
    i=1
    while read -r line; do
        i=$(( i + 1 ))
        echo $i
    done < <(rpi-update)
    } | whiptail --title "Progress" --gauge "Please wait while updating your RPI firmware and kernel" $WT_HEIGHT $WT_WIDTH
fi
}

##################### Raspi-config 3.64

do_raspi_config() {
  if [ $(dpkg-query -W -f='${Status}' raspi-config 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
  raspi-config
else
  wget http://archive.raspberrypi.org/debian/pool/main/r/raspi-config/raspi-config_20160527_all.deb -P /tmp
  apt-get install libnewt0.52 whiptail parted triggerhappy lua5.1 -y
  dpkg -i /tmp/raspi-config_20160527_all.deb
  whiptail --msgbox "Raspi-config is now installed, run it by typing: sudo raspi-config" $WT_HEIGHT $WT_WIDTH
  raspi-config
fi
}

################################ Show folder size 3.7

do_foldersize() {
	if [ $(dpkg-query -W -f='${Status}' ncdu 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
      ncdu /
else
      apt-get install ncdu -y
	    ncdu /
fi
}

################################ Show folder content and permissions 3.8

do_listdir() {
	LISTDIR=$(whiptail --inputbox "Directory to list? Eg. /mnt/yourfolder" --title "Navigate with TAB to hit ok to enter input" $WT_HEIGHT $WT_WIDTH 3>&1 1>&2 2>&3)
	LISTDIR1=$(ls -la "$LISTDIR")
	whiptail --msgbox "$LISTDIR1" $WT_HEIGHT $WT_WIDTH --scrolltext --title "Scroll with your mouse or page up/down or arrow keys"
}

################################ Show connected devices 3.9

do_blkid() {
  BLKID=$(blkid)
  whiptail --msgbox "$BLKID" $WT_HEIGHT $WT_WIDTH --scrolltext --title "Scroll with your mouse or page up/down or arrow keys"
}

################################ Show disk usage 3.10

do_df() {
  DF=$(df -h)
  whiptail --msgbox "$DF" $WT_HEIGHT $WT_WIDTH --scrolltext --title "Scroll with your mouse or page up/down or arrow keys"
}

################################ Show system performance 3.11

do_htop() {
	if [ $(dpkg-query -W -f='${Status}' htop 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    htop
else

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get install htop -y)
  } | whiptail --title "Progress" --gauge "Please wait while installing Htop..." $WT_HEIGHT $WT_WIDTH

    htop
fi
}

################################ Disable IPV6 3.12

do_disable_ipv6() {
 if grep -q "net.ipv6.conf.all.disable_ipv6 = 1" "/etc/sysctl.conf"; then
   sleep 0
 else
 echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
 fi

 if grep -q "net.ipv6.conf.default.disable_ipv6 = 1" "/etc/sysctl.conf"; then
   sleep 0
 else
 echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
 fi

  if grep -q "net.ipv6.conf.lo.disable_ipv6 = 1" "/etc/sysctl.conf"; then
   sleep 0
 else
 echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
 fi

 echo
 sysctl -p
 echo

 whiptail --msgbox "IPV6 is now disabled..." $WT_HEIGHT $WT_WIDTH
}

################################ Find string text 3.13

do_find_string() {
        STRINGTEXT=$(whiptail --inputbox "Text that you want to search for? eg. ip mismatch: 192.168.1.133" $WT_HEIGHT $WT_WIDTH 3>&1 1>&2 2>&3)
        STRINGDIR=$(whiptail --inputbox "Directory you want to search in? eg. / for whole system or /home" $WT_HEIGHT $WT_WIDTH 3>&1 1>&2 2>&3)
        STRINGCMD=$(grep -Rl "$STRINGTEXT" "$STRINGDIR")
        whiptail --msgbox "$STRINGCMD" $WT_HEIGHT $WT_WIDTH
}

################################ Reboot on out of memory 3.14

do_oom() {
 if grep -q kernel.panic=10 "/etc/sysctl.d/oom_reboot.conf"; then
   sleep 0
 else
 echo "kernel.panic=10" >> /etc/sysctl.d/oom_reboot.conf
 fi

 if grep -q vm.panic_on_oom=1 "/etc/sysctl.d/oom_reboot.conf"; then
   sleep 0
 else
 echo "vm.panic_on_oom=1" >> /etc/sysctl.d/oom_reboot.conf
 fi

 echo
 sysctl -p /etc/sysctl.d/oom_reboot.conf
 echo

 whiptail --msgbox "System will now reboot on out of memory errors..." $WT_HEIGHT $WT_WIDTH
}

################################ 3.15



################################  3.16



################################ 3.17



################################ Set dns to google and opendns 3.19

do_dns() {
  # Clear existing DNS servers
  cat /dev/null > /etc/resolv.conf
  cat /dev/null > /etc/resolvconf/resolv.conf.d/tail
  cat /dev/null > /etc/resolvconf/resolv.conf.d/head
  cat /dev/null > /etc/resolvconf/resolv.conf.d/base
  #cat /dev/null > /etc/resolvconf/resolv.conf.d/original
  echo "options timeout:1 rotate attempts:1" > /etc/resolvconf/resolv.conf.d/tail
  echo "nameserver 8.8.8.8 #Google NS1" >> /etc/resolvconf/resolv.conf.d/tail
  echo "nameserver 8.8.4.4 #Google NS2" >> /etc/resolvconf/resolv.conf.d/tail
  echo "nameserver 208.67.222.222 #OpenDNS1" >> /etc/resolvconf/resolv.conf.d/tail
  echo "nameserver 208.67.220.220 #OpenDNS2" >> /etc/resolvconf/resolv.conf.d/tail
  resolvconf -u
  ifdown -a; ifup -a

  whiptail --msgbox "Dns is now set to google, if no response in 1 second it switches to opendns..." $WT_HEIGHT $WT_WIDTH
}

################################ Progress bar 3.20

do_progressbar() {
if grep -q Dpkg::Progress-Fancy "1"; "/etc/apt/apt.conf.d/99progressbar"; then
  echo
  echo "Already installed..."
else
  echo "Dpkg::Progress-Fancy "1";" > /etc/apt/apt.conf.d/99progressbar

	whiptail --msgbox "You now have a fancy progress bar, outside this installer run apt or apt-get install <package>" $WT_HEIGHT $WT_WIDTH
fi
}

################################ Boot terminal 3.21

do_bootterminal() {
if grep -q GRUB_CMDLINE_LINUX_DEFAULT="" "/etc/default/grub"; then
  sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT=""|GRUB_CMDLINE_LINUX_DEFAULT="text"|g' /etc/default/grub
  update-grub
  whiptail --msgbox "System now boots to terminal..." $WT_HEIGHT $WT_WIDTH
fi
}

################################ Boot gui 3.22

do_bootgui() {
  if grep -q GRUB_CMDLINE_LINUX_DEFAULT="text" "/etc/default/grub"; then
    sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="text"|GRUB_CMDLINE_LINUX_DEFAULT=""|g' /etc/default/grub
  	update-grub

    whiptail --msgbox "System now boots to desktop..." $WT_HEIGHT $WT_WIDTH
  fi
}

################################ Swappiness 3.23

do_swappiness() {
SWAPPINESS=$(whiptail --inputbox "Set the swappiness value" $WT_HEIGHT $WT_WIDTH 0 3>&1 1>&2 2>&3)

if grep -q vm.swappiness "/etc/sysctl.conf"; then
    sed -i '/vm.swappiness/d' /etc/sysctl.conf
  	echo "vm.swappiness = $SWAPPINESS" >> /etc/sysctl.conf
  	sysctl -p

    whiptail --msgbox "Swappiness is set..." $WT_HEIGHT $WT_WIDTH
else
  echo "vm.swappiness = $SWAPPINESS" >> /etc/sysctl.conf
  sysctl -p

  whiptail --msgbox "Swappiness is set..." $WT_HEIGHT $WT_WIDTH
fi
}

################################ Delete line containing string 3.24

do_stringdel() {
DELETESTRING=$(whiptail --inputbox "Which line containing the following string needs to be deleted?" $WT_HEIGHT $WT_WIDTH "eg. address 192.168.1.1" 3>&1 1>&2 2>&3)
DELETESTRINGFILE=$(whiptail --inputbox "In what file should we search?" $WT_HEIGHT $WT_WIDTH "eg. /etc/network" 3>&1 1>&2 2>&3)

sed -i "/$DELETESTRING/d" "$DELETESTRINGFILE"
whiptail --title "This is your updated file" --textbox "$DELETESTRINGFILE" $WT_HEIGHT $WT_WIDTH
}

################################ Kernel upgrade 3.25

do_ukupgrade() {
mkdir -p $SCRIPTS
wget https://raw.githubusercontent.com/muhasturk/ukupgrade/master/ukupgrade -P $SCRIPTS
bash $SCRIPTS/ukupgrade

whiptail --msgbox "Kernel upgraded..." $WT_HEIGHT $WT_WIDTH
}

################################  Backup system 3.26

do_backup() {
  {
  i=1
  while read -r line; do
      i=$(( $i + 1 ))
      echo $i
  done < <(tar cvpjf /backup.tar.bz2 --exclude=/proc --exclude=/dev --exclude=/media --exclude=/lost+found --exclude=/backup.tar.bz2 --exclude=/mnt --exclude=/sys /)
} | whiptail --title "Progress" --gauge "Please wait while backing up your system..." $WT_HEIGHT $WT_WIDTH

whiptail --msgbox "Backup finished..." $WT_HEIGHT $WT_WIDTH
}

################################  Restore Backup 3.27

do_restore_backup() {
  if 		[ -f /backup.tar.bz2 ]; then
  {
  i=1
  while read -r line; do
      i=$(( $i + 1 ))
      echo $i
  done < <(tar xvpfj backup.tar.bz2 -C /)
} | whiptail --title "Progress" --gauge "Please wait while restoring your system..." $WT_HEIGHT $WT_WIDTH

  mkdir -p proc
  mkdir -p media
  mkdir -p lost+found
  mkdir -p mnt
  mkdir -p sys
  mkdir -p dev

  whiptail --msgbox "Restoring the backup is finished..." $WT_HEIGHT $WT_WIDTH
  ASK_TO_REBOOT=1
else
  whiptail --msgbox "Could not find the backup file make sure you made the backup..." $WT_HEIGHT $WT_WIDTH
fi
}

################################  Fail2Ban SSH 3.28

do_fail2ban_ssh() {
PORT1=$(whiptail --inputbox "SSH port? Default port is 22" --title "Navigate with TAB to hit ok to enter input" $WT_HEIGHT $WT_WIDTH 22)

if [ $(dpkg-query -W -f='${Status}' fail2ban 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
      echo "Fail2Ban is already installed!"
      cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
      sed -i 's|port     = ssh|port     = "$PORT1"|g' /etc/fail2ban/jail.local
      sed -i 's|bantime  = 600|bantime  = 1200|g' /etc/fail2ban/jail.local
      sed -i 's|maxretry = 3|maxretry = 5"|g' /etc/fail2ban/jail.local
      service fail2ban restart
      whiptail --msgbox "SSH is now protected with Fail2Ban..." $WT_HEIGHT $WT_WIDTH
else
      apt-get install fail2ban -y
      cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
      sed -i 's|port     = ssh|port     = "$PORT1"|g' /etc/fail2ban/jail.local
      sed -i 's|bantime  = 600|bantime  = 1200|g' /etc/fail2ban/jail.local
      sed -i 's|maxretry = 3|maxretry = 5"|g' /etc/fail2ban/jail.local
      service fail2ban restart
      whiptail --msgbox "SSH is now protected with Fail2Ban..." $WT_HEIGHT $WT_WIDTH
fi
}

################################  Google auth SSH 3.29

do_2fa() {
USERNAME=$(whiptail --inputbox "Username you want to enable 2 factor authentication for?" --title "Navigate with TAB to hit ok to enter input" $WT_HEIGHT $WT_WIDTH)

  whiptail --msgbox "WARNING \
  Please make sure to save the codes presented to you before logging out. \
  Failing to do so, will lock you out of your system. \
  You can at any time find the keys in /var/google-authenticator" $WT_HEIGHT $WT_WIDTH

  if [ $(dpkg-query -W -f='${Status}' openssh-client 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "OpenSSH client is already installed!"

else
  apt-get install openssh-client -y

  whiptail --msgbox "SSH client is now installed..." $WT_HEIGHT $WT_WIDTH
fi

if [ $(dpkg-query -W -f='${Status}' libpam-google-authenticator 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
      echo "libpam-google-authenticator is already installed!"
else
    apt-get install libpam-google-authenticator -y
sudo -u $USERNAME google-authenticator > /root/google-authenticator << EOF
y
y
y
n
y
EOF

  echo "auth required pam_google_authenticator.so" >> /etc/pam.d/sshd
  sed -i 's|ChallengeResponseAuthentication no|ChallengeResponseAuthentication yes|g' /etc/ssh/sshd_config
  service ssh restart
  echo "AuthenticationMethods password,publickey,keyboard-interactive" >> /etc/ssh/sshd_config
  sed -i 's|@include common-auth|#@include common-auth|g' /etc/pam.d/sshd
  service ssh restart

  whiptail --msgbox "SSH is now protected with 2FA, next you will see your codes, add them to the google auth. app. Please write down the keys on a piece of paper you see in the next screen. /var/google-authenticator holds your keys..." $WT_HEIGHT $WT_WIDTH
  whiptail --textbox "/var/google-authenticator" $WT_HEIGHT $WT_WIDTH --title "Please scroll down to the keys" --scrolltext
fi
}

################################ Do distribution upgrade 3.30

do_ltsupgrade() {
  apt-get update
  apt-get dist-upgrade -y

if [ $(dpkg-query -W -f='${Status}' update-manager-core 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
      echo "update-manager-core is already installed!"
else
      apt-get install update-manager-core -y
fi

if grep -q Prompt "/etc/update-manager/release-upgrades"; then
  sed -i "/Prompt/d" "/etc/update-manager/release-upgrades"
  echo "Prompt=lts" >> /etc/update-manager/release-upgrades
else
  echo "Prompt=lts" >> /etc/update-manager/release-upgrades
fi

do-release-upgrade -d << EOF
y
y
y
EOF

ASK_TO_REBOOT=1
}

################################################ Install 4

do_install() {
  FUN=$(whiptail --backtitle "Install software packages" --title "Tech and Tool - https://www.techandme.se" --menu "Tech and tool" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
      "I1 Install Package" "User defined" \
      "I2 Install Webmin" "Graphical interface to manage headless systems" \
      "I3 Install SSH Server" "Needed by a remote machine to be accessable via SSH" \
      "I4 Install SSH Client" "Needed by the local machine to connect to a remote machine" \
      "I5 Change SSH-server port" "Change SSH-server port" \
      "I6 Install ClamAV" "Antivirus, set daily scans, infections will be emailed" \
      "I7 Install Fail2Ban" "Install a failed login monitor, needs jails for apps!!!!" \
      "I8 Install Nginx" "Install Nginx webserver" \
      "I9 Install Teamspeak" "Install Teamspeak 3 server to do voice chat" \
      "I10 Install NFS Client" "Install NFS client to be able to mount NFS shares" \
      "I11 Install NFS Server" "Install NFS server to be able to broadcast NFS shares" \
      "I12 Install DDClient" "Update Dynamic Dns with WAN IP, dyndns.com, easydns.com etc." \
      "I13 Install AtoMiC-ToolKit" "Installer for Sabnzbd, Sonar, Couchpotato etc." \
      "I14 Install OpenVPN" "Connect to an OpenVPN server to secure your connections" \
      "I15 Install Network manager" "Advanced network tools" \
      "I16 Install NextCloud" "Your own Dropbox/google drive" \
      "I17 Install Plex" "Powerfull Media manager, also sets daily updates" \
      "I18 Install Vnc server" "With LXDE minimal/core desktop, only use with SSH." \
      "I19 Install Zram-config" "For devices with low RAM, compresses your RAM content (RPI)" \
      "I20 Install Virtualbox" "Virtualize any OS Windows, ubuntu etc." \
      "I21 Install Virtualbox extension pack" "Expand Virtualbox's capability's" \
      "I22 Install Virtualbox guest additions" "Enables features such as USB, shared folders etc. in side the guest" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      I1\ *) do_install_package ;;
      I2\ *) do_install_webmin ;;
      I3\ *) do_install_SSH_server ;;
      I4\ *) do_install_SSH_client ;;
      I5\ *) do_ssh ;;
      I6\ *) do_clamav ;;
      I7\ *) do_fail2ban ;;
      I8\ *) do_nginx ;;
      I9\ *) do_teamspeak ;;
      I10\ *) do_install_nfs_client ;;
      I11\ *) do_install_nfs_server ;;
      I12\ *) do_install_ddclient ;;
      I13\ *) do_atomic ;;
      I14\ *) do_openvpn ;;
      I15\ *) do_install_networkmanager ;;
      I16\ *) do_nextcloud ;;
      I17\ *) do_install_plex ;;
      I18\ *) do_install_vnc ;;
      I19\ *) do_install_zram ;;
      I20\ *) do_virtualbox ;;
      I21\ *) do_vboxextpack ;;
      I22\ *) do_vboxguestadd ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
 else
   exit 1
  fi
}

################################ Install package 4.1

do_install_package() {
	PACKAGE=$(whiptail --inputbox "Package name?" --title "Navigate with TAB to hit ok to enter input" $WT_HEIGHT $WT_WIDTH)

	if [ $(dpkg-query -W -f='${Status}' $PACKAGE 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "$PACKAGE is already installed!"

else
	apt-get install $PACKAGE -y
  whiptail --msgbox "$PACKAGE is now installed..." $WT_HEIGHT $WT_WIDTH
fi
}

################################ Install webmin 4.2

do_install_webmin() {
  echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
  cd /root
  wget http://www.webmin.com/jcameron-key.asc
  apt-key add jcameron-key.asc
  apt-get update
  apt-get install webmin -y
  ufw allow 10000/tcp
  cd

whiptail --msgbox "Webmin is now installed, access it at https://$ADDRESS:10000..." $WT_HEIGHT $WT_WIDTH
}

################################ Install SSH server 4.3

do_install_SSH_server() {
  if [ $(dpkg-query -W -f='${Status}' openssh-server 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "OpenSSH server is already installed!"
        sed -i 's|PermitEmptyPasswords yes|PermitEmptyPasswords no|g' /etc/ssh/sshd_config

else
  apt-get install openssh-server -y
  sed -i 's|PermitEmptyPasswords yes|PermitEmptyPasswords no|g' /etc/ssh/sshd_config
  whiptail --msgbox "SSH server is now installed..." $WT_HEIGHT $WT_WIDTH
fi
}

################################ Install SSH client 4.4

do_install_SSH_client() {
  if [ $(dpkg-query -W -f='${Status}' openssh-client 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "OpenSSH client is already installed!"

else
  apt-get install openssh-client -y

  whiptail --msgbox "SSH client is now installed..." $WT_HEIGHT $WT_WIDTH
fi
}

################################ Change SSH port 4.5

do_ssh() {
PORT=$(whiptail --inputbox "New SSH port?" --title "Navigate with TAB to hit ok to enter input" $WT_HEIGHT $WT_WIDTH)
  	ufw allow $PORT/tcp
  	ufw deny 22
  	sed -i "s|22|$PORT|g" /etc/ssh/sshd_config
  whiptail --msgbox "SSH port is now changed to $PORT and your firewall rules are updated..." $WT_HEIGHT $WT_WIDTH
}

################################ Install ClamAV 4.6

do_clamav() {
TOMAIL=$(whiptail --inputbox "What email should receive mail when system is infected?" --title "Navigate with TAB to hit ok to enter input" $WT_HEIGHT $WT_WIDTH)

  if [ $(dpkg-query -W -f='${Status}' clamav 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    apt-get remove clamav clamav-freshclam -y
  fi

  apt-get install clamav clamav-freshclam heirloom-mailx -y
  service ClamAV-freshclam start
  mkdir -p /var/scripts

  cat <<-CLAMSCAN > "/var/scripts/clamscan_daily.sh"
  #!/bin/bash
  LOGFILE="/var/log/clamav/clamav-$(date +'%Y-%m-%d').log";
  EMAIL_MSG="Please see the log file attached.";
  EMAIL_FROM="www.techandme.se@gmail.com";
  EMAIL_TO="$TOMAIL";
  DIRTOSCAN="/";

  for S in ${DIRTOSCAN}; do
   DIRSIZE=$(du -sh "$S" 2>/dev/null | cut -f1);

   echo "Starting a daily scan of "$S" directory.
   Amount of data to be scanned is "$DIRSIZE".";

   clamscan -ri "$S" >> "$LOGFILE";

   # get the value of "Infected lines"
   MALWARE=$(tail "$LOGFILE"|grep Infected|cut -d" " -f3);

   # if the value is not equal to zero, send an email with the log file attached
   if [ "$MALWARE" -ne "0" ];then
   # using heirloom-mailx below
   echo "$EMAIL_MSG"|mail -a "$LOGFILE" -s "Malware Found" -r "www.techandme.se@gmail.com" "$EMAIL_TO";
   fi
  done

  exit 0
CLAMSCAN

  chmod 0755 /root/clamscan_daily.sh
  ln /root/clamscan_daily.sh /etc/cron.daily/clamscan_daily

  whiptail --msgbox "ClamAV is now installed..." $WT_HEIGHT $WT_WIDTH
}

################################ Install Fail2Ban 4.7

do_fail2ban() {
  if [ $(dpkg-query -W -f='${Status}' fail2ban 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "Fail2ban server is already installed!"
else
  apt-get install fail2ban -y
  whiptail --msgbox "Fail2Ban is now installed..." $WT_HEIGHT $WT_WIDTH
fi
}

################################ Install Nginx 4.8

do_nginx() {
  if [ $(dpkg-query -W -f='${Status}' Nginx 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "Nginx server is already installed!"
else
  apt-get install nginx -y
  ufw allow 443/tcp
  ufw allow 80/tcp

  whiptail --msgbox "Nginx is now installed, also port 443 and 80 are open in the firewall..." $WT_HEIGHT $WT_WIDTH
fi
}

################################ Install Teamspeak  4.9

do_teamspeak() {
# Add user
useradd teamspeak3
sed -i 's|:/home/teamspeak3:|:/home/teamspeak3:/usr/sbin/nologin|g' /etc/passwd

# Get Teamspeak
wget http://ftp.4players.de/pub/hosted/ts3/releases/3.0.10.3/teamspeak3-server_linux-amd64-3.0.10.3.tar.gz -P /tmp

# Unpack Teamspeak
tar xzf /tmp/teamspeak3-server_linux-amd64-3.0.10.3.tar.gz

# Move to right directory
mv /tmp/teamspeak3-server_linux-amd64 /usr/local/teamspeak3

# Set ownership
chown -R teamspeak3 /usr/local/teamspeak3

# Add to upstart
ln -s /usr/local/teamspeak3/ts3server_startscript.sh /etc/init.d/teamspeak3
update-rc.d teamspeak3 defaults

# Warning
echo -e "\e[32m"
echo    "+--------------------------------------------------------------------+"
echo    "| Next you will need to copy/paste 3 things to a safe location       |"
echo    "|                                                                    |"
echo -e "|         \e[0mLOGIN, PASSWORD, SECURITY TOKEN\e[32m                            |"
echo    "|                                                                    |"
echo -e "|         \e[0mIF YOU FAIL TO DO SO, YOU HAVE TO REINSTALL TEAMSPEAK\e[32m    |"
echo -e "|         \e[0mIn 30 Sec the script will continue, so be quick!/e[32m           |"
echo    "+--------------------------------------------------------------------+"
echo
read -p "Press any key to start copying the important stuff to a safe location..." -n1 -s
echo -e "\e[0m"
echo

# Start service
service teamspeak3 start && sleep 30
echo
function ask_yes_or_no() {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}

ufw allow 9987/udp
ufw allow 30033/tcp
ufw allow 10011/tcp
ufw allow 41144/tcp

whiptail --msgbox "Teamspeak is now installed..." $WT_HEIGHT $WT_WIDTH
}

################################ Install NFS client 4.10

do_install_nfs_client() {
  if [ $(dpkg-query -W -f='${Status}' nfs-common 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "NFS client is already installed!"

else
  apt-get install nfs-common -y

  whiptail --msgbox 'Installed! Auto mount like this: echo "<nfs-server-IP>:/   /mount_point   nfs    auto  0  0" >> /etc/fstab' $WT_HEIGHT $WT_WIDTH
fi
}

################################ Install NFS server 4.11

do_install_nfs_server() {
  if [ $(dpkg-query -W -f='${Status}' nfs-kernel-server 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "NFS server is already installed!"

else
  apt-get install nfs-kernel-server -y
  ufw allow 2049

  whiptail --msgbox "Installed! You can broadcast your NFS server and set it up in webmin (when installed): https://$ADDRESS:10000" $WT_HEIGHT $WT_WIDTH
fi
}

################################ Install DDclient 4.12

do_install_ddclient() {
function ask_yes_or_no() {
    read -p "$1 ([y]es or [N]o): "
    case $(echo $REPLY | tr '[A-Z]' '[a-z]') in
        y|yes) echo "yes" ;;
        *)     echo "no" ;;
    esac
}
if [[ "yes" == $(ask_yes_or_no "Do you have a DynDns service purchased at DynDns.com or Easydns etc?") ]]
then
	echo
    	echo "If the script asks for a network device fill in this: $IFACE"
    	echo -e "\e[32m"
    	read -p "Press any key to continue... " -n1 -s
    	echo -e "\e[0m"
	sudo apt-get install ddclient -y
	echo "ddclient" >> /etc/cron.daily/dns-update.sh
	chmod 755 /etc/cron.daily/dns-update.sh
else
sleep 1
fi
}

################################  Install AtoMiC-ToolKit 4.13

do_atomic() {
  	apt-get -y install git-core
if 		[ -d /root/AtoMiC-ToolKit ]; then
    echo "Atomic toolkit already installed..."
else
  	#cd /root
  	git clone https://github.com/htpcBeginner/AtoMiC-ToolKit ~/AtoMiC-ToolKit
  	#cd
fi
    whiptail --msgbox "AtoMiC-ToolKit is now installed, run it with: cd ~/AtoMiC-ToolKit && sudo bash setup.sh" $WT_HEIGHT $WT_WIDTH
    cd ~/AtoMiC-ToolKit
  	bash setup.sh
  	cd
}

################################ Install Network-manager 4.15

do_install_networkmanager() {
  if [ $(dpkg-query -W -f='${Status}' network-manager 2>/dev/null | grep -c "ok installed") -eq 1 ];
  then
        echo "network-manager is already installed!"
  else
        apt-get install network-manager -y
        whiptail --msgbox "Network-manager is now installed..." $WT_HEIGHT $WT_WIDTH
  fi
}

################################ Install Nextcloud 4.16

do_nextcloud() {
mkdir -p $SCRIPTS
wget https://raw.githubusercontent.com/nextcloud/vm/master/nextcloud_install_production.sh -P $SCRIPTS
bash $SCRIPTS/nextcloud_install_production.sh
}

################################ Install OpenVpn 4.17

do_openvpn() {
if [ $(dpkg-query -W -f='${Status}' openvpn 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
  echo "OpenVpn is already installed!"
else
  apt-get install openvpn -y

  if [ $(dpkg-query -W -f='${Status}' network-manager-openvpn 2>/dev/null | grep -c "ok installed") -eq 1 ];
  then
        echo "network-manager-openvpn is already installed!"
  else
        apt-get install network-manager-openvpn -y
  fi

  whiptail --msgbox "OpenVpn is now installed..." $WT_HEIGHT $WT_WIDTH
fi
}

################################ Install Plex 4.18

do_install_plex() {
  if [ $(dpkg-query -W -f='${Status}' wget 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "Wget is already installed!"
else
  apt-get install wget -y
fi

if [ $(dpkg-query -W -f='${Status}' nfs-kernel-server 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
      echo "Git is already installed!"
else
apt-get install git -y
fi

  wget https://downloads.plex.tv/plex-media-server/0.9.16.6.1993-5089475/plexmediaserver_0.9.16.6.1993-5089475_amd64.deb -P /tmp/
	dpkg -i /tmp/plexmediaserver_0.9.16.6.1993-5089475_amd64.deb
	cd /root

if 		[ -d /root/plexupdate ];
then
	rm -r /root/plexupdate
fi

	git clone https://github.com/mrworf/plexupdate.git
	touch /root/.plexupdate
	cat <<-PLEX > "/root/.plexupdate"
	DOWNLOADDIR="/tmp"
	RELEASE="64"
	KEEP=no
	FORCE=no
	PUBLIC=yes
	AUTOINSTALL=yes
	AUTODELETE=yes
	AUTOUPDATE=yes
  AUTOSTART=yes
	PLEX
if 		[ -f /etc/cron.daily/plex.sh ]; then
   sleep 0
else
	echo "bash /root/plexupdate/plexupdate.sh" >> /etc/cron.daily/plex.sh
	chmod 754 /etc/cron.daily/plex.sh
fi
whiptail --msgbox "Plex is now installed..." $WT_HEIGHT $WT_WIDTH
}

################################ Install VNC server 4.19

do_install_vnc() {
  if [ $(dpkg-query -W -f='${Status}' thightvncserver 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "VNC is already installed!"
else
  apt-get install xorg lxde-core tightvncserver -y
  tightvncserver :1
  tightvncserver -kill :1
  echo 'lxterminal &' >> ~/.vnc/xstartup
  echo '/usr/bin/lxsession -s LXDE &' >> ~/.vnc/xstartup
  /usr/bin/lxsession -s LXDE &
  tightvncserver :1
  ufw allow 5901
  whiptail --msgbox "Firewall port updated (5901). Start: tightvncserver - Stop tightvncserver -kill :1" $WT_HEIGHT $WT_WIDTH
fi
}

################################ Install Zram-config 4.20

do_install_zram() {
if [ $(dpkg-query -W -f='${Status}' zram-config 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
      echo "Zram is already installed!"
else
apt-get install zram-config -y
whiptail --msgbox "Zram-config is now installed..." $WT_HEIGHT $WT_WIDTH
ASK_TO_REBOOT=1
fi
}

################################ Install virtualbox 4.21

do_virtualbox() {
echo "deb http://download.virtualbox.org/virtualbox/debian xenial contrib" >> /etc/apt/sources.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

# Install req packages
    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get update)
  } | whiptail --title "Progress" --gauge "Please wait while updating..." $WT_HEIGHT $WT_WIDTH

# Install req packages
    {
    i=1
    while read -r line; do
        i=$(( i + 1 ))
        echo $i
    done < <(apt-get install virtualbox-dkms dkms build-essential linux-headers-generic linux-headers-$(uname -r) virtualbox-5.1 -y)
  } | whiptail --title "Progress" --gauge "Please wait while installing the required packages..." $WT_HEIGHT $WT_WIDTH

sudo modprobe vboxdrv

whiptail --msgbox "Virtualbox is now installed..." $WT_HEIGHT $WT_WIDTH
}

################################ Install virtualbox extension pack 4.22

do_vboxextpack() {
wget http://download.virtualbox.org/virtualbox/5.1.4/Oracle_VM_VirtualBox_Extension_Pack-5.1.4-110228.vbox-extpack -P $SCRIPTS/
vboxmanage extpack install $SCRIPTS/http://download.virtualbox.org/virtualbox/5.1.4/Oracle_VM_VirtualBox_Extension_Pack-5.1.4-110228.vbox-extpack

whiptail --msgbox "Virtualbox extension pack is installed..." $WT_HEIGHT $WT_WIDTH
}

################################ Install virtualbox guest additions 4.23

do_vboxguestadd() {
apt-get update
apt-get install virtualbox-guest-additions-iso -y
mkdir -p /mnt
mkdir -p /mnt/tmp
mount /usr/share/virtualbox/VBoxGuestAdditions.iso /mnt/tmp
cd /mnt/tmp
./VBoxLinuxAdditions.run
cd
umount /mnt/tmp
rm -rf /mnt/tmp

whiptail --msgbox "Virtualbox guest additions are now installed, make sure to reboot..." $WT_HEIGHT $WT_WIDTH
ASK_TO_REBOOT=1
}

################################################ Firewall 5

do_firewall() {
  FUN=$(whiptail  --backtitle "Firewall" --title "Tech and Tool - https://www.techandme.se" --menu "Firewall options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
    "A0 Enable Firewall" "" \
    "A1 Disable Firewall" "" \
    "A2 Show current rules" "" \
    "!! Reset Firewall" "Be carefull only do this if you know what you're doing" \
    "A3 Allow port Multiple" "Teamspeak" \
    "A4 Allow port 32400" "Plex" \
    "A5 Allow port 8989" "Sonarr" \
    "A6 Allow port 5050" "Couchpotato" \
    "A7 Allow port 8181" "Headphones" \
    "A8 Allow port 8085" "HTPC Manager" \
    "A9 Allow port 8080" "Mylar" \
    "A10 Allow port 10000" "Webmin" \
    "A11 Allow port 8080" "Sabnzbdplus" \
    "A12 Allow port 9090" "Sabnzbdplus https" \
    "A13 Allow port 2049" "NFS" \
    "A14 Deny port Multiple" "Teamspeak" \
    "A15 Deny port 32400" "Plex" \
    "A16 Deny port 8989" "Sonarr" \
    "A17 Deny port 5050" "Couchpotato" \
    "A18 Deny port 8181" "Headphones" \
    "A19 Deny port 8085" "HTPC Manager" \
    "A20 Deny port 8080" "Mylar" \
    "A21 Deny port 10000" "Webmin" \
    "A22 Deny port 8080" "Sabnzbdplus" \
    "A23 Deny port 9090" "Sabnzbdplus https" \
    "A24 Deny port 2049" "NFS" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      A0\ *) do_ufw_enable ;;
      A1\ *) do_ufw_disable ;;
      A2\ *) do_ufw_status ;;
      !!\ *) do_ufw_reset ;;
      A3\ *) do_allow_teamspeak ;;
      A4\ *) do_allow_32400 ;;
      A5\ *) do_allow_8989 ;;
      A6\ *) do_allow_5050 ;;
      A7\ *) do_allow_8181 ;;
      A8\ *) do_allow_8085 ;;
      A9\ *) do_allow_mylar ;;
      A10\ *) do_allow_10000 ;;
      A11\ *) do_allow_8080 ;;
      A12\ *) do_allow_9090 ;;
      A13\ *) do_allow_2049 ;;
      A14\ *) do_deny_teamspeak ;;
      A15\ *) do_deny_32400 ;;
      A16\ *) do_deny_8989 ;;
      A17\ *) do_deny_5050 ;;
      A18\ *) do_deny_8181 ;;
      A19\ *) do_deny_8085 ;;
      A20\ *) do_deny_mylar ;;
      A21\ *) do_deny_10000 ;;
      A22\ *) do_deny_8080 ;;
      A23\ *) do_deny_9090 ;;
      A24\ *) do_deny_2049 ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

######################################################################################
####################################TO DO#############################################
# Tcp/udp
# http/https
# Phpmyadmin
# Ufw delete xxx
# Ufw reset
######Firewall#######
do_ufw_enable() {
#sudo ufw reset << EOF
#y
#EOF
sudo ufw enable
sudo ufw default deny incoming
sudo ufw status
sleep 2
whiptail --msgbox "Firewall is now enabled..." $WT_HEIGHT $WT_WIDTH
}
######Firewall#######
do_ufw_disable() {
sudo ufw disable
sudo ufw status
sleep 2
whiptail --msgbox "Firewall is now disabled, you are at risk..." $WT_HEIGHT $WT_WIDTH
}
######Firewall#######
do_ufw_status() {
STATUS=$(sudo ufw status)
whiptail --msgbox "$STATUS" $WT_HEIGHT $WT_WIDTH
}
######Firewall#######
do_ufw_reset() {
sudo ufw reset << EOF
y
EOF
whiptail --msgbox "Firewall is now reset please set your rules..." $WT_HEIGHT $WT_WIDTH
}
######Firewall#######
do_allow_32400() {
sudo ufw allow 32400
sudo ufw status
sleep 2
}
######Firewall#######
do_allow_10000() {
sudo ufw allow 10000
sudo ufw status
sleep 2
}
######Firewall#######
do_allow_5050() {
sudo ufw allow 5050
sudo ufw status
sleep 2
}
######Firewall#######
do_allow_9090() {
sudo ufw allow 9090
sudo ufw status
sleep 2
}
######Firewall#######
do_allow_8080() {
sudo ufw allow 8080
sudo ufw status
sleep 2
}
######Firewall#######
do_allow_8989() {
sudo ufw allow 8989
sudo ufw status
sleep 2
}
######Firewall#######
do_allow_8181() {
sudo ufw allow 8181
sudo ufw status
sleep 2
}
######Firewall#######
do_allow_8085() {
sudo ufw allow 8085
sudo ufw status
sleep 2
}
######Firewall#######
do_allow_mylar() {
sudo ufw allow 8080
sudo ufw status
sleep 2
}
######Firewall#######
do_allow_2049() {
sudo ufw allow 2049
sudo ufw status
sleep 2
}
######Firewall#######
do_allow_teamspeak() {
sudo ufw allow 9987
sudo ufw allow 10011
sudo ufw allow 30033
sudo ufw status
sleep 2
}
######Firewall#######
do_deny_32400() {
sudo ufw deny 32400
sudo ufw status
sleep 2
}
######Firewall#######
do_deny_10000() {
sudo ufw deny 10000
sudo ufw status
sleep 2
}
######Firewall#######
do_deny_5050() {
sudo ufw deny 5050
sudo ufw status
sleep 2
}
######Firewall#######
do_deny_9090() {
sudo ufw deny 9090
sudo ufw status
sleep 2
}
######Firewall#######
do_deny_8080() {
sudo ufw deny 8080
sudo ufw status
sleep 2
}
######Firewall#######
do_deny_8989() {
sudo ufw deny 8989
sudo ufw status
sleep 2
}
######Firewall#######
do_deny_8181() {
sudo ufw deny 8181
sudo ufw status
sleep 2
}
######Firewall#######
do_deny_8085() {
sudo ufw deny 8085
sudo ufw status
sleep 2
}
######Firewall#######
do_deny_mylar() {
sudo ufw deny 8080
sudo ufw status
sleep 2
}
######Firewall#######
do_deny_2049() {
sudo ufw deny 2049
sudo ufw status
sleep 2
}
######Firewall#######
do_deny_teamspeak() {
sudo ufw deny 9987
sudo ufw deny 10011
sudo ufw deny 30033
sudo ufw status
sleep 2
}
################################# Update 6

do_update() {

  if [ $(dpkg-query -W -f='${Status}' aptitude 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "Aptitude is already installed!"
  else
      apt-get install aptitude -y
  fi

   {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get autoclean)
    } | whiptail --title "Progress" --gauge "Please wait while auto cleaning" $WT_HEIGHT $WT_WIDTH

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get autoremove -y)
    } | whiptail --title "Progress" --gauge "Please wait while auto removing un-needed dependancies" $WT_HEIGHT $WT_WIDTH

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get update)
    } | whiptail --title "Progress" --gauge "Please wait while updating" $WT_HEIGHT $WT_WIDTH

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get upgrade -y)
    } | whiptail --title "Progress" --gauge "Please wait while ugrading" $WT_HEIGHT $WT_WIDTH

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get install -fy)
    } | whiptail --title "Progress" --gauge "Please wait while forcing install of dependancies" $WT_HEIGHT $WT_WIDTH

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get dist-upgrade -y)
    } | whiptail --title "Progress" --gauge "Please wait while doing dist-upgrade" $WT_HEIGHT $WT_WIDTH

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(aptitude full-upgrade -y)
    } | whiptail --title "Progress" --gauge "Please wait while upgrading with aptitude" $WT_HEIGHT $WT_WIDTH

	dpkg --configure --pending

	mkdir -p $SCRIPTS

	if [ -f $SCRIPTS/techandtool.sh ]
then
        rm $SCRIPTS/techandtool.sh
        rm /usr/sbin/techandtool
fi
        wget https://github.com/ezraholm50/vm/raw/master/static/techandtool.sh -P $SCRIPTS
        cp $SCRIPTS/techandtool.sh /usr/sbin/techandtool
        exit | bash $SCRIPTS/techandtool.sh
}

################################################ About 7

do_about() {
  whiptail --msgbox "\
This tool is created by techandme.se for less skilled linux terminal users.

It makes it easy just browsing the menu and installing or using system tools.

Please post requests (with REQUEST in title) here: https://github.com/ezraholm50/techandtool/issues

Note that this tool is tested on Ubuntu 16.04 (should work on debian)

Visit https://www.techandme.se for awsome free virtual machines,
Nextcloud, ownCloud, Teamspeak, Wordpress, Minecraft etc.\
" $WT_HEIGHT $WT_WIDTH
}

################################################ Main menu 8

calc_wt_size
while true; do
  FUN=$(whiptail --backtitle "Tech and Tool main menu" --title "Tech and Tool - https://www.techandme.se" --menu "Tech and tool" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
    "1 Apps" "Nextcloud" \
    "2 Tools" "Various tools" \
    "3 Packages" "Install various software packages" \
    "4 Firewall" "Enable/disable and open/close ports" \
    "5 Raspberry" "Specific tools for RPI 1, 2, 3 and zero" \
    "6 Update & upgrade" "Updates and upgrades packages and get the latest version of this tool" \
    "7 Reboot" "Reboots your machine" \
    "8 Shutdown" "Shutdown your machine" \
    "9 About Tech and Tool" "Information about this tool" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
	do_finish
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) do_apps ;;
      2\ *) do_tools ;;
      3\ *) do_install ;;
      4\ *) do_firewall ;;
      5\ *) do_Raspberry ;;
      6\ *) do_update ;;
      7\ *) do_reboot ;;
      8\ *) do_poweroff ;;
      9\ *) do_about ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
 else
   exit 1
  fi
done

do_reboot() {
	reboot
}

do_poweroff() {
	shutdown now
}
