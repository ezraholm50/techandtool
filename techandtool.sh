#!/bin/bash
#
# VERSION=1.0.0
#
# Tech and Me, 2016 - www.techandme.se
#
# Whiptail menu to install various Nextcloud app and do other useful stuf.
#
# To do
# Backup & restore, 2FA, ukupgrade, Collabora, Spreed, Gpxpod, if success then msg on do_*
#
##### Index ######
# 1 Variable / requirements
# 1.0 Network
# 1.1 Network vars
# 1.2 Raspberry - can get expand
# 1.3 Fix nasty locale error over SSH
# 1.4 Whiptail size
# 1.5 Whiptail check
# 1.6 Root check
# 1.7 Update notification
# 1.8 Vacant
# 1.9 Ask to reboot
# 1.10 Check Ubuntu OS
# 2 Tech and Me
# 2.1 Install Nextcloud
# 2.2 Install Nextcloud Apps
# 2.91 Collabora
# 2.92 Spreed-webrtc
# 2.93 Gpxpod
# 2.3 Install Wordpress
# 2.4 Install NextBerry
# 2.5 Install Teamspeak
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
# 3.15 Notify email upon ROOT login SSH
# 3.16 Notify email upon $USER login SSH
# 3.17 Vacant
# 3.18 Vacant
# 3.19 Set dns to google and opendns
# 3.20 Progressbar
# 3.21 Boot terminal
# 3.22 Boot gui
# 3.23 Set swappiness
# 3.24 Delete line containing string
# 3.25 Upgrade kernel
# 3.26 Vacant
# 3.27 Vacant
# 4 Install packages menu
# 4.1 Install packages
# 4.2 Install Webmin
# 4.3 Install SSH server
# 4.4 Install SSH client
# 4.5 Install Change SSH port
# 4.6 Install ClamAV
# 4.7 Install Fail2Ban
# 4.8 Install Nginx
# 4.9 Vacant
# 4.10 Install NFS client
# 4.11 Install NFS server
# 4.12 Install DDclient
# 4.13 Install Atomic-Toolkit
# 4.14 Install Plesk
# 4.15 Install Network-manager
# 4.16 Vacant
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

INTERACTIVE=True
REPO='https://raw.githubusercontent.com/ezraholm50/techandtool/master'
COLLABORAREPO='https://raw.githubusercontent.com/ezraholm50/collabora-auto/master'
SPREEDREPO='https://raw.githubusercontent.com/ezraholm50/Spreed-auto/master'
NCREPO='https://raw.githubusercontent.com/nextcloud/vm/master'
WORDPRESSREPO='https://raw.githubusercontent.com/enoch85/wordpress-vm/master/'
NEXTBERRYREPO='https://raw.githubusercontent.com/ezraholm50/NextBerry/master'

################################ Network vars 1.1

IFCONFIG=$(ifconfig)
clear
IP="/sbin/ip"
IFACE=$(lshw -c network | grep "logical name" | awk '{print $3}')
clear
INTERFACES="/etc/network/interfaces"
clear
ADDRESS=$($IP route get 1 | awk '{print $NF;exit}')
NETMASK=$(ifconfig "$IFACE" | grep Mask | sed s/^.*Mask://)
GATEWAY=$($IP route | awk '/default/ { print $3 }')

if ! [ -x "$(command -v nslookup)" ]; then
	apt-get install dnsutils -y -q
else
	echo 'dnsutils is installed.' >&2
  clear
fi
if ! [ -x "$(command -v ifup)" ]; then
	apt-get install ifupdown -y -q
else
	echo 'ifupdown is installed.' >&2
  clear
fi

nslookup google.com
if [[ $? > 0 ]]
then
	whiptail --msgbox "Network NOT OK. You must have a working Network connection to run this script." "$WT_HEIGHT" "$WT_WIDTH"
        exit 1
else
	echo "Network OK."
  clear
fi

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

################################ Fix nasty locale error over SSH 1.3

if [ $(dpkg-query -W -f='${Status}' openssh-server 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
  if grep -q "#SendEnv LANG LC_*" "/etc/ssh/ssh_config"; then
    echo "Fix already applied..."
    clear
  else
    sed -i "s|SendEnv|#SendEnv|g" /etc/ssh/ssh_config
    service ssh restart
  fi

  if grep -q "#AcceptEnv LANG LC_*" "/etc/ssh/sshd_config"; then
    echo "Fix already applied..."
    clear
  else
    sed -i "s|AcceptEnv|#AcceptEnv|g" /etc/ssh/sshd_config
    service ssh restart
  fi
fi

################################ Whiptail size 1.4

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

	if [ $(dpkg-query -W -f='${Status}' whiptail 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "Whiptail is already installed..."
        clear
else

    {
    i=1
    while read -r line; do
        i=$(( i + 1 ))
        echo $i
    done < <(apt-get install whiptail -y)
  } | whiptail --title "Progress" --gauge "Please wait while installing Whiptail..." 6 60 0

fi

################################################ Check if root 1.6

if [ "$(whoami)" != "root" ]; then
        whiptail --msgbox "Sorry you are not root. You must type: sudo techandtool" "$WT_HEIGHT" "$WT_WIDTH"
        exit
fi

################################ Update notification 1.7

CURRENTVERSION=$(grep -m1 "# VERSION=" /usr/sbin/techandtool)
GITHUBVERSION=$(curl -s $REPO/version)
SCRIPTS="/var/scripts"

if [ $(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
      echo "Curl is already installed..."
      clear
else
    apt-get install curl -y
fi

#  if [ -f /tmp/version ]; then
#          rm /tmp/version
#  fi

if [ "$CURRENTVERSION" == "$GITHUBVERSION" ]; then
          echo "Tool is up to date..."
else

  whiptail --yesno "A new version of this tool is available, download it now?" --title "Update Notification!" 10 60 2
  if [ $? -eq 0 ]; then # yes

  if [ -f "$SCRIPTS"/techandtool.sh ]; then
          rm "$SCRIPTS"/techandtool.sh
  fi

  if [ -f /usr/sbin/techandtool ]; then
          rm /usr/sbin/techandtool
  fi
          mkdir -p "$SCRIPTS"
          wget -q $REPO/techandtool.sh -P "$SCRIPTS"
          cp "$SCRIPTS"/techandtool.sh /usr/sbin/techandtool
          chmod +x /usr/sbin/techandtool

          if [ -f "$SCRIPTS"/techandtool.sh ]; then
                  rm "$SCRIPTS"/techandtool.sh
          fi

          exec techandtool
    fi
fi

################################################ 1.8



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

################################################ Check Ubuntu OS 1.10

DISTRO=$(lsb_release -sd | cut -d ' ' -f 2)
version(){
    local h t v

    [[ $2 = "$1" || $2 = "$3" ]] && return 0

    v=$(printf '%s\n' "$@" | sort -V)
    h=$(head -n1 <<<"$v")
    t=$(tail -n1 <<<"$v")

    [[ $2 != "$h" && $2 != "$t" ]]
}

if ! version 16.04 "$DISTRO" 16.04.10; then
    whiptail --msgbox "Ubuntu version $DISTRO is tested on 16.04 - 16.04.10 no support is given for other releases." "$WT_HEIGHT" "$WT_WIDTH"
    #exit
fi

if [ $(dpkg-query -W -f='${Status}' ubuntu-server 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  	whiptail --msgbox "'ubuntu-server' is not installed, this doesn't seem to be a server. Please install the server version of Ubuntu and restart the script" "$WT_HEIGHT" "$WT_WIDTH"
    exit 1
fi

################################################ Techandme 2


do_techandme() {
  FUN=$(whiptail --backtitle "Tech and Me VM's" --title "Tech and Tool - https://www.techandme.se" --menu "Tech and tool" "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" --cancel-button Back --ok-button Select \
  "0 Install Nextcloud" "Requires a clean Ubuntu 16.04 server" \
  "1 Install Nextcloud apps" "" \
  "2 Install Wordpress" "Requires a clean Ubuntu 16.04 server" \
  "3 Install NextBerry" "Requires a clean Ubuntu 16.04 server on RPI 2 or 3" \
  "4 Install Teamspeak" "Requires Ubuntu 16.04 server" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      0\ *) do_nextcloud ;;
      1\ *) do_apps ;;
      2\ *) do_wordpress ;;
      3\ *) do_nextberry ;;
      4\ *) do_teamspeak ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
 else
   exit 1
  fi
}

################################################ Install Nextcloud 2.1

do_nextcloud() {
mkdir -p "$SCRIPTS"
wget "$NCREPO"/nextcloud_install_production.sh -P "$SCRIPTS"
bash "$SCRIPTS"/nextcloud_install_production.sh
}

################################################ Install Nextcloud apps 2.2

do_apps() {
  FUN=$(whiptail --backtitle "Apps" --title "Tech and Tool - https://www.techandme.se" --menu "Tech and tool" "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" --cancel-button Back --ok-button Select \
  "1 Collabora" "Docker" \
  "2 Spreed-webrtc" "Spreedme" \
  "3 Gpxpod" "" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) do_collabora ;;
      2\ *) do_spreed_webrtc ;;
      3\ *) do_gpxpod ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
 else
   exit 1
  fi
}

################### Collabora 2.91

do_collabora() {
  whiptail --msgbox "Under construction..." "$WT_HEIGHT" "$WT_WIDTH"
  #wget $COLLABORAREPO/install.sh -P $SCRIPTS
  #mv $SCRIPTS/install.sh $SCRIPTS/collaborainstall.sh
  #bash $SCRIPTS/collaborainstall.sh
}

################### Spreed-webrtc 2.92

do_spreed_webrtc() {
whiptail --msgbox "Under construction..." "$WT_HEIGHT" "$WT_WIDTH"
#wget $SPREEDREPO/install.sh -P $SCRIPTS
#mv $SCRIPTS/install.sh $SCRIPTS/spreedinstall.sh
#bash $SCRIPTS/spreedinstall.sh
}

################### Gpxpod 2.93

do_gpxpod() {
	whiptail --msgbox "Under construction..." "$WT_HEIGHT" "$WT_WIDTH"
}

################################################ Install Wordpress 2.3

do_wordpress() {
mkdir -p "$SCRIPTS"
wget "$WORDPRESSREPO"/wordpress_install.sh -P "$SCRIPTS"
bash "$SCRIPTS"/wordpress_install.sh
}

################################################ Install Nextberry 2.4

do_nextberry() {
mkdir -p "$SCRIPTS"
wget "$NEXTBERRYREPO"/nextcloud_install_production.sh -P "$SCRIPTS"
bash "$SCRIPTS"/nextcloud_install_production.sh
}

################################################ Install Teamspeak 2.5

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

whiptail --msgbox "Teamspeak is now installed..." "$WT_HEIGHT" "$WT_WIDTH"
}

################################################ Tools 3

do_tools() {
FUN=$(whiptail --backtitle "Tools" --title "Tech and Tool - Tools - https://www.techandme.se" --menu "Tech and tool" "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" --cancel-button Back --ok-button Select \
"1 Show LAN IP, Gateway, Netmask" "Ifconfig" \
"2 Show WAN IP" "External IP address" \
"3 Change Hostname" "Your machine's name" \
"4 Internationalisation Options" "Change language, time, date and keyboard layout" \
"5 Connect to WLAN" "Please have a wifi dongle/card plugged in before start" \
"6 Show folder size" "Using ncdu" \
"7 Show folder content" "with permissions" \
"8 Show connected devices" "blkid" \
"9 Show disks usage" "df -h" \
"10 Show system performance" "HTOP" \
"11 Disable IPV6" "Via sysctl.conf" \
"12 Find text" "In a given directory" \
"13 OOM fix" "Auto reboot on out of memory errors" \
"14 Generate new SSH keys" "" \
"18 Set dns to Google and OpenDns" "Try google first if no response after 1 sec. switch to next NS" \
"19 Add progress bar" "Apply's to apt-get update, install & upgrade" \
"20 Boot to terminal by default" "Only if you use a GUI/desktop now" \
"21 Boot to GUI/desktop by default" "Only if you have a GUI installed and have terminal as default" \
"22 Delete line containing a string of text" "Warning, deletes every line containing the string!" \
"23 Set swappiness" "" \
"24 Upgrade Ubuntu Kernel" "To the latest version" \
"25 Backup your system" "" \
"26 Restore backup" "Made with the option above" \
"27 Protect SSH with Fail2Ban" "" \
"28 Protect SSH with Google 2 factor authentication" "" \
"29 Distribution upgrade" "Only LTS" \
"30 Notify email address upon SSH login" "Only for 'ROOT'" \
"31 Notify email address upon SSH login" "User defined account" \
  3>&1 1>&2 2>&3)
RET=$?
if [ $RET -eq 1 ]; then
  return 0
elif [ $RET -eq 0 ]; then
  case "$FUN" in
    1\ *) do_ifconfig ;;
    2\ *) do_wan_ip ;;
    3\ *) do_change_hostname ;;
    4\ *) do_internationalisation_menu ;;
    5\ *) do_wlan ;;
    6\ *) do_foldersize ;;
    7\ *) do_listdir ;;
    8\ *) do_blkid ;;
    9\ *) do_df ;;
    10\ *) do_htop ;;
    11\ *) do_disable_ipv6 ;;
    12\ *) do_find_string ;;
    13\ *) do_oom ;;
		14\ *) do_ssh_keys ;;
    18\ *) do_dns ;;
    19\ *) do_progressbar ;;
    20\ *) do_bootterminal ;;
    21\ *) do_bootgui ;;
    22\ *) do_stringdel ;;
    23\ *) do_swappiness ;;
    24\ *) do_ukupgrade ;;
    25\ *) do_backup ;;
    26\ *) do_restore_backup ;;
    27\ *) do_fail2ban_ssh ;;
    28\ *) do_2fa ;;
    29\ *) do_ltsupgrade ;;
    30\ *) do_rootmailssh ;;
    31\ *) do_usermailssh ;;
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
" "$WT_HEIGHT" "$WT_WIDTH"
}

################################ Wan IP 3.2

do_wan_ip() {
  WAN=$(wget -qO- http://ipecho.net/plain ; echo)
  whiptail --msgbox "WAN IP: $WAN" "$WT_HEIGHT" "$WT_WIDTH"
}

################################ Hostname 3.3

do_change_hostname() {
  whiptail --msgbox "\
Please note: RFCs mandate that a hostname's labels \
may contain only the ASCII letters 'a' through 'z' (case-insensitive),
the digits '0' through '9', and the hyphen.
Hostname labels cannot begin or end with a hyphen.
No other symbols, punctuation characters, or blank spaces are permitted.\
" "$WT_HEIGHT" "$WT_WIDTH"

  CURRENT_HOSTNAME=$(cat < /etc/hostname | tr -d " \t\n\r")
  NEW_HOSTNAME=$(whiptail --inputbox "Please enter a hostname" 20 60 "$CURRENT_HOSTNAME" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    echo "$NEW_HOSTNAME" > /etc/hostname
    sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
  fi

  CURRENT_HOSTNAME1=$(cat < /etc/hostname | tr -d " \t\n\r")
  whiptail --msgbox "This is your new current hostname: $CURRENT_HOSTNAME1" "$WT_HEIGHT" "$WT_WIDTH"
}

################################ Internationalisation 3.4

do_internationalisation_menu() {
  FUN=$(whiptail --backtitle "Internationalisation" --title "Tech and Tool - https://www.techandme.se" --menu "Internationalisation Options" "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" --cancel-button Back --ok-button Select \
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

do_wlan() {
whiptail --yesno "Do you want to connect to wifi? Its recommended to use a wired connection for your Nextcloud server!" --yes-button "Wireless" --no-button "Wired" "$WT_HEIGHT" "$WT_WIDTH"
if [ $? -eq 0 ]; then # yes
      apt-get install linux-firmware wicd-curses wicd-daemon wicd-cli -y
      wicd-curses
			#whiptail --msgbox "In the next screen navigate with the arrow keys (right arrow for config) and don't for get to select auto connect at the networks config settings." "$WT_HEIGHT" "$WT_WIDTH"
      #whiptail --msgbox "Due to the new interface the DHCP server gave you a new ip:\n\n'$ADDRESS' \n\n If the NIC starts with 'wl', you're good to go and you can unplug the ethernet cable: \n\n '$IFACE'" "$WT_HEIGHT" "$WT_WIDTH"

else
        		echo "We'll use a wired connection..."
fi
}

################################ Raspberry specific 3.6

do_Raspberry() {
  FUN=$(whiptail --backtitle "Raspberry" --title "Tech and Tool - https://www.techandme.se" --menu "Raspberry" "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" --cancel-button Back --ok-button Select \
  "1 Resize SD" "" \
  "2 External USB" "Use an USB HD/SSD as root" \
  "3 RPI-update" "Update the RPI firmware and kernel" \
  "4 Raspi-config" "Set various settings, not all are tested! Already safely overclocked!" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) do_expand_rootfs "$@";;
      2\ *) do_external_usb ;;
      3\ *) do_rpi_update ;;
      4\ *) do_raspi_config ;;
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

  whiptail --msgbox "Root partition has been resized.\nThe filesystem will be enlarged upon the next reboot" "$WT_HEIGHT" "$WT_WIDTH"
  ASK_TO_REBOOT=1
	do_finish
}

##################### External USB 3.62

do_external_usb() {
	whiptail --msgbox "Under construction..." "$WT_HEIGHT" "$WT_WIDTH"
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
  } | whiptail --title "Progress" --gauge "Please wait while updating your RPI firmware and kernel" 6 60 0
else
    apt-get install rpi-update -y

	  {
    i=1
    while read -r line; do
        i=$(( i + 1 ))
        echo $i
    done < <(rpi-update)
  } | whiptail --title "Progress" --gauge "Please wait while updating your RPI firmware and kernel" 6 60 0
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
  whiptail --msgbox "Raspi-config is now installed, run it by typing: sudo raspi-config" "$WT_HEIGHT" "$WT_WIDTH"
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
	LISTDIR=$(whiptail --inputbox "Directory to list? Eg. /mnt/yourfolder" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
	LISTDIR1=$(ls -la "$LISTDIR")
	whiptail --msgbox "$LISTDIR1" "$WT_HEIGHT" "$WT_WIDTH" --scrolltext --title "Scroll with your mouse or page up/down or arrow keys"
}

################################ Show connected devices 3.9

do_blkid() {
  BLKID=$(blkid)
  whiptail --msgbox "$BLKID" "$WT_HEIGHT" "$WT_WIDTH" --scrolltext --title "Scroll with your mouse or page up/down or arrow keys"
}

################################ Show disk usage 3.10

do_df() {
  DF=$(df -h)
  whiptail --msgbox "$DF" "$WT_HEIGHT" "$WT_WIDTH" --scrolltext --title "Scroll with your mouse or page up/down or arrow keys"
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
  } | whiptail --title "Progress" --gauge "Please wait while installing Htop..." 6 60 0

    htop
fi
}

################################ Disable IPV6 3.12

do_disable_ipv6() {
 if grep -q "net.ipv6.conf.all.disable_ipv6 = 1" "/etc/sysctl.conf"; then
   echo "Already applied..."
 else
 echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
 fi

 if grep -q "net.ipv6.conf.default.disable_ipv6 = 1" "/etc/sysctl.conf"; then
   echo "Already applied..."
 else
 echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
 fi

  if grep -q "net.ipv6.conf.lo.disable_ipv6 = 1" "/etc/sysctl.conf"; then
   echo "Already applied..."
 else
 echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
 fi

 echo
 sysctl -p
 echo

if grep -q "net.ipv6.conf.all.disable_ipv6 = 1" "/etc/sysctl.conf"; then
   whiptail --msgbox "IPV6 is now disabled..." "$WT_HEIGHT" "$WT_WIDTH"
fi
}

################################ Find string text 3.13

do_find_string() {
        STRINGTEXT=$(whiptail --inputbox "Text that you want to search for? eg. ip mismatch: 192.168.1.133" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
        STRINGDIR=$(whiptail --inputbox "Directory you want to search in? eg. / for whole system or /home" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
        STRINGCMD=$(grep -Rl "$STRINGTEXT" "$STRINGDIR")
        whiptail --msgbox "$STRINGCMD" "$WT_HEIGHT" "$WT_WIDTH" --scrolltext
}

################################ Reboot on out of memory 3.14

do_oom() {
 if grep -q "kernel.panic=10" "/etc/sysctl.d/oom_reboot.conf"; then
   echo "Already applied..."
 else
 echo "kernel.panic=10" >> /etc/sysctl.d/oom_reboot.conf
 fi

 if grep -q "vm.panic_on_oom=1" "/etc/sysctl.d/oom_reboot.conf"; then
   echo "Already applied..."
 else
 echo "vm.panic_on_oom=1" >> /etc/sysctl.d/oom_reboot.conf
 fi

 echo
 sysctl -p /etc/sysctl.d/oom_reboot.conf
 echo

 whiptail --msgbox "System will now reboot on out of memory errors..." "$WT_HEIGHT" "$WT_WIDTH"
}

################################ Mail when ROOT logs into SSH 3.15

do_rootmailssh() {
CURRENT_HOSTNAME=$(cat < /etc/hostname | tr -d " \t\n\r")
MAILADDRESS=$(whiptail --inputbox "Mail for notification?" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)

if [ $(dpkg-query -W -f='${Status}' mailutils 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    echo "mailutils is already installed..."
else
    apt-get install mailutils -y
fi

if grep -q "ALERT - Root Shell Access" "/root/.bashrc"; then
  echo "Already applied..."
else
echo "echo 'ALERT - Root Shell Access ("$CURRENT_HOSTNAME") on:' `date` `who` | mail -s "Alert: Root Access from `who | cut -d'(' -f2 | cut -d')' -f1`" "$MAILADDRESS"" >> /root/.bashrc
  if [ $? -eq 1 ]; then
    whiptail --msgbox "There where errors running this command. Please run this tool in debug mode: sudo bash -x /usr/sbin/techandtool" "$WT_HEIGHT" "$WT_WIDTH"
  else
    whiptail --msgbox "Installed email notification upon login of the ROOT user. Please logout and test it." "$WT_HEIGHT" "$WT_WIDTH"
  fi
fi
}

################################  Mail when $USER logs into SSH 3.16

do_usermailssh() {
CURRENT_HOSTNAME=$(cat < /etc/hostname | tr -d " \t\n\r")
MAILADDRESS=$(whiptail --inputbox "Mail for notification?" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
USER=$(whiptail --inputbox "User that you want to be notified for upon login? (case sensetive)" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)

if [ $(dpkg-query -W -f='${Status}' mailutils 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    echo "mailutils is already installed..."
else
    apt-get install mailutils -y
fi

if grep -q "ALERT - Root Shell Access" "/home/$USER/.bashrc"; then
  echo "Already applied..."
else
echo "echo 'ALERT - $USER Shell Access ("$CURRENT_HOSTNAME") on:' `date` `who` | mail -s "Alert: $USER Access from `who | cut -d'(' -f2 | cut -d')' -f1`" "$MAILADDRESS"" >> /home/$USER/.bashrc
  if [ $? -eq 1 ]; then
    whiptail --msgbox "There where errors running this command. Please run this tool in debug mode: sudo bash -x /usr/sbin/techandtool" "$WT_HEIGHT" "$WT_WIDTH"
  else
    whiptail --msgbox "Installed email notification upon login of the specified user. Please logout and test it." "$WT_HEIGHT" "$WT_WIDTH"
  fi
fi
}

################################ Generate new SSH keys 3.17

do_ssh_keys() {
	rm -v /etc/ssh/ssh_host_*
	dpkg-reconfigure openssh-server
}

################################ Set dns to google and opendns 3.19

do_dns() {
  # Backup & Clear existing DNS servers
  mkdir -p /etc/resolvconf/resolv.conf.d.backup
  cp -R /etc/resolv.conf /etc/resolvconf/resolv.conf.d.backup/
  cp -R /etc/resolvconf/resolv.conf.d/* /etc/resolvconf/resolv.conf.d.backup/

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

  nslookup google.com
if [[ $? > 0 ]]
then
  	whiptail --msgbox "Network NOT OK. Reverting old settings..." "$WT_HEIGHT" "$WT_WIDTH"
    cp -R /etc/resolvconf/resolv.conf.d.backup/resolv.conf /etc/resolv.conf
    cp -R /etc/resolvconf/resolv.conf.d.backup/* /etc/resolvconf/resolv.conf.d/

    resolvconf -u
    ifdown -a; ifup -a

    nslookup google.com
    if [[ $? > 0 ]]
    then
    whiptail --msgbox "There where errors running this command. Please run this tool in debug mode: sudo bash -x /usr/sbin/techandtool" "$WT_HEIGHT" "$WT_WIDTH"
    else
    whiptail --msgbox "Settings reverted succesfully..." "$WT_HEIGHT" "$WT_WIDTH"
    fi
else
    whiptail --msgbox "Dns is now set to google, if no response in 1 second it switches to opendns..." "$WT_HEIGHT" "$WT_WIDTH"
fi
}

################################ Progress bar 3.20

do_progressbar() {
if grep -q "Dpkg::Progress-Fancy "1";" "/etc/apt/apt.conf.d/99progressbar"; then
  whiptail --msgbox "Already installed..." "$WT_HEIGHT" "$WT_WIDTH"
else
  echo "Dpkg::Progress-Fancy "1";" > /etc/apt/apt.conf.d/99progressbar
  if [ $? -eq 1 ]; then
    whiptail --msgbox "There where errors running this command. Please run this tool in debug mode: sudo bash -x /usr/sbin/techandtool" "$WT_HEIGHT" "$WT_WIDTH"
  else
	  whiptail --msgbox "You now have a fancy progress bar, outside this installer run apt or apt-get install <package>" "$WT_HEIGHT" "$WT_WIDTH"
  fi
fi
}

################################ Boot terminal 3.21

do_bootterminal() {
if grep -q "GRUB_CMDLINE_LINUX_DEFAULT="splash quiet"" "/etc/default/grub"; then
  sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="splash quiet"|GRUB_CMDLINE_LINUX_DEFAULT="text"|g' /etc/default/grub
  update-grub
  if [ $? -eq 1 ]; then
    whiptail --msgbox "There where errors running this command. Please run this tool in debug mode: sudo bash -x /usr/sbin/techandtool" "$WT_HEIGHT" "$WT_WIDTH"
  else
    whiptail --msgbox "System now boots to terminal..." "$WT_HEIGHT" "$WT_WIDTH"
  fi
fi

if grep -q "GRUB_CMDLINE_LINUX_DEFAULT=""" "/etc/default/grub"; then
  sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT=""|GRUB_CMDLINE_LINUX_DEFAULT="text"|g' /etc/default/grub
  update-grub
  if [ $? -eq 1 ]; then
    whiptail --msgbox "There where errors running this command. Please run this tool in debug mode: sudo bash -x /usr/sbin/techandtool" "$WT_HEIGHT" "$WT_WIDTH"
  else
    whiptail --msgbox "System now boots to terminal..." "$WT_HEIGHT" "$WT_WIDTH"
  fi
fi
}

################################ Boot gui 3.22

do_bootgui() {
if grep -q GRUB_CMDLINE_LINUX_DEFAULT="splash quiet" "/etc/default/grub"; then
  sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="splash quiet"|GRUB_CMDLINE_LINUX_DEFAULT=""|g' /etc/default/grub
  update-grub
  if [ $? -eq 1 ]; then
    whiptail --msgbox "There where errors running this command. Please run this tool in debug mode: sudo bash -x /usr/sbin/techandtool" "$WT_HEIGHT" "$WT_WIDTH"
  else
    whiptail --msgbox "System now boots to desktop..." "$WT_HEIGHT" "$WT_WIDTH"
  fi
fi

  if grep -q GRUB_CMDLINE_LINUX_DEFAULT="text" "/etc/default/grub"; then
    sed -i 's|GRUB_CMDLINE_LINUX_DEFAULT="text"|GRUB_CMDLINE_LINUX_DEFAULT=""|g' /etc/default/grub
  	update-grub
    if [ $? -eq 1 ]; then
      whiptail --msgbox "There where errors running this command. Please run this tool in debug mode: sudo bash -x /usr/sbin/techandtool" "$WT_HEIGHT" "$WT_WIDTH"
    else
      whiptail --msgbox "System now boots to desktop..." "$WT_HEIGHT" "$WT_WIDTH"
    fi
  fi
}

################################ Swappiness 3.23

do_swappiness() {
SWAPPINESS=$(whiptail --inputbox "Set the swappiness value" "$WT_HEIGHT" "$WT_WIDTH" 0 3>&1 1>&2 2>&3)

if grep -q "vm.swappiness" "/etc/sysctl.conf"; then
    sed -i '/vm.swappiness/d' /etc/sysctl.conf
  	echo "vm.swappiness = $SWAPPINESS" >> /etc/sysctl.conf
  	sysctl -p

    whiptail --msgbox "Swappiness is set..." "$WT_HEIGHT" "$WT_WIDTH"
else
  echo "vm.swappiness = $SWAPPINESS" >> /etc/sysctl.conf
  sysctl -p

  whiptail --msgbox "Swappiness is set..." "$WT_HEIGHT" "$WT_WIDTH"
fi
}

################################ Delete line containing string 3.24

do_stringdel() {
DELETESTRING=$(whiptail --inputbox "Which line containing the following string needs to be deleted?" "$WT_HEIGHT" "$WT_WIDTH" "eg. address 192.168.1.1" 3>&1 1>&2 2>&3)
DELETESTRINGFILE=$(whiptail --inputbox "In what file should we search?" "$WT_HEIGHT" "$WT_WIDTH" "eg. /etc/network" 3>&1 1>&2 2>&3)

sed -i "/$DELETESTRING/d" "$DELETESTRINGFILE"
whiptail --title "This is your updated file" --textbox "$DELETESTRINGFILE" "$WT_HEIGHT" "$WT_WIDTH" --scrolltext
}

################################ Kernel upgrade 3.25

do_ukupgrade() {
mkdir -p "$SCRIPTS"
wget https://raw.githubusercontent.com/muhasturk/ukupgrade/master/ukupgrade -P "$SCRIPTS"
bash "$SCRIPTS"/ukupgrade

whiptail --msgbox "Kernel upgraded..." "$WT_HEIGHT" "$WT_WIDTH"
}

################################  Backup system 3.26

do_backup() {
HOSTNAME=$(cat < /etc/hostname | tr -d " \t\n\r")
DATE=$(date "+%F")
BACKUPFILE="$HOSTNAME-$DATE.tar.bz2"

tar -cvpjf /$BACKUPFILE --xattrs --absolute-names --exclude=/proc --exclude=/dev --exclude=/media --exclude=/lost+found --exclude=/$BACKUPFILE --exclude=/mnt --exclude=/sys / #&& whiptail --msgbox "Backup finished, backup.tar.bz2 is located in /" "$WT_HEIGHT" "$WT_WIDTH"
if [ $? -eq 1 ]; then
  whiptail --msgbox "There where errors running this command. Please run this tool in debug mode: sudo bash -x /usr/sbin/techandtool" "$WT_HEIGHT" "$WT_WIDTH"
else
  whiptail --msgbox "Backup finished, $BACKUPFILE is located in /" "$WT_HEIGHT" "$WT_WIDTH"
  echo "$BACKUPFILE" > /var/scripts/donotremove-backupfile
fi
}

################################  Restore Backup 3.27

do_restore_backup() {
  whiptail --msgbox "Under construction..." "$WT_HEIGHT" "$WT_WIDTH"
#BACKUPFILE=$(cat /var/scripts/donotremove-backupfile)

#if [ -f /$BACKUPFILE ]; then
#  mkdir -p proc
#  mkdir -p media
#  mkdir -p lost+found
#  mkdir -p mnt
#  mkdir -p sys
#  mkdir -p dev

#  tar --bzip2 -xvpf /$BACKUPFILE -C / && whiptail --msgbox "Restoring the backup is finished..." "$WT_HEIGHT" "$WT_WIDTH" && ASK_TO_REBOOT=1 && do_finish
#else
#  whiptail --msgbox "Could not find the backup file make sure you made the backup..." "$WT_HEIGHT" "$WT_WIDTH"
#fi
}

################################  Fail2Ban SSH 3.28

do_fail2ban_ssh() {
PORT1=$(whiptail --inputbox "SSH port? Default port is 22" "$WT_HEIGHT" "$WT_WIDTH" 22 3>&1 1>&2 2>&3)

if [ $(dpkg-query -W -f='${Status}' fail2ban 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
      echo "Fail2Ban is already installed!"
      sed -i "s|port     = ssh|port     = $PORT1|g" /etc/fail2ban/jail.local
      sed -i 's|bantime  = 600|bantime  = 1200|g' /etc/fail2ban/jail.local
      sed -i 's|maxretry = 3|maxretry = 5"|g' /etc/fail2ban/jail.local
      service fail2ban restart
      whiptail --msgbox "SSH is now protected with Fail2Ban..." "$WT_HEIGHT" "$WT_WIDTH"
else
      apt-get install fail2ban -y
      cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
      sed -i "s|port     = ssh|port     = $PORT1|g" /etc/fail2ban/jail.local
      sed -i 's|bantime  = 600|bantime  = 1200|g' /etc/fail2ban/jail.local
      sed -i 's|maxretry = 3|maxretry = 5"|g' /etc/fail2ban/jail.local
      service fail2ban restart
      whiptail --msgbox "SSH is now protected with Fail2Ban..." "$WT_HEIGHT" "$WT_WIDTH"
fi
}

################################  Google auth SSH 3.29

do_2fa() {
USERNAME=$(whiptail --inputbox "Username you want to enable 2 factor authentication for?" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)

whiptail --msgbox "\
WARNING\
Please make sure to save the codes presented to you before logging out.
Failing to do so, will lock you out of your system.
You can at any time find the keys in /var/google-authenticator\
" "$WT_HEIGHT" "$WT_WIDTH"

if [ $(dpkg-query -W -f='${Status}' openssh-server 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "OpenSSH server is already installed!"

else
  apt-get install openssh-server -y
fi

if [ $(dpkg-query -W -f='${Status}' libpam-google-authenticator 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
      echo "libpam-google-authenticator is already installed!"
else
    apt-get install libpam-google-authenticator -y
sudo -u $USERNAME google-authenticator > /var/google-authenticator << EOF
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
  chmod 600 /var/google-authenticator

  whiptail --msgbox "SSH is now protected with 2FA, next you will see your codes, add them to the google auth. app. Please write down the keys on a piece of paper you see in the next screen. /var/google-authenticator holds your keys..." "$WT_HEIGHT" "$WT_WIDTH"
  whiptail --textbox "/var/google-authenticator" "$WT_HEIGHT" "$WT_WIDTH" --title "Please scroll down to the keys" --scrolltext
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

if grep -q "Prompt" "/etc/update-manager/release-upgrades"; then
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
do_finish
}

################################################ Install 4

do_install() {

  {
  i=1
  while read -r line; do
      i=$(( $i + 1 ))
      echo $i
  done < <(apt-get update)
} | whiptail --title "Progress" --gauge "Please wait while updating" 6 60 0

  FUN=$(whiptail --backtitle "Install software packages" --title "Tech and Tool - https://www.techandme.se" --menu "Tech and tool" "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" --cancel-button Back --ok-button Select \
      "I1 Install Package" "User defined" \
      "I2 Install Webmin" "Graphical interface to manage headless systems" \
      "I3 Install SSH Server" "Needed by a remote machine to be accessable via SSH" \
      "I4 Install SSH Client" "Needed by the local machine to connect to a remote machine" \
      "I5 Change SSH-server port" "Change SSH-server port" \
      "I6 Install ClamAV" "Antivirus, set daily scans, infections will be emailed" \
      "I7 Install Fail2Ban" "Install a failed login monitor, needs jails for apps!!!!" \
      "I8 Install Nginx" "Install Nginx webserver" \
      "I9 Install Zram-config" "For devices with low RAM, compresses your RAM content (RPI)" \
      "I10 Install NFS Client" "Install NFS client to be able to mount NFS shares" \
      "I11 Install NFS Server" "Install NFS server to be able to broadcast NFS shares" \
      "I12 Install DDClient" "Update Dynamic Dns with WAN IP, dyndns.com, easydns.com etc." \
      "I13 Install AtoMiC-ToolKit" "Installer for Sabnzbd, Sonar, Couchpotato etc." \
      "I14 Install OpenVPN" "Connect to an OpenVPN server to secure your connections" \
      "I15 Install Network manager" "Advanced network tools" \
      "I16 Install Plesk" "Hosting platform, ONLY for a clean Ubuntu 14.04 server!" \
      "I17 Install Plex" "Powerfull Media manager, also sets daily updates" \
      "I18 Install Vnc server" "With LXDE minimal/core desktop, only use with SSH." \
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
      I9\ *) do_install_zram ;;
      I10\ *) do_install_nfs_client ;;
      I11\ *) do_install_nfs_server ;;
      I12\ *) do_install_ddclient ;;
      I13\ *) do_atomic ;;
      I14\ *) do_openvpn ;;
      I15\ *) do_install_networkmanager ;;
      I16\ *) do_plesk ;;
      I17\ *) do_install_plex ;;
      I18\ *) do_install_vnc ;;
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
	PACKAGE=$(whiptail --inputbox "Package name?" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)

	if [ $(dpkg-query -W -f='${Status}' $PACKAGE 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "$PACKAGE is already installed!"
else
	apt-get install "$PACKAGE" -y
  whiptail --msgbox "$PACKAGE is now installed..." "$WT_HEIGHT" "$WT_WIDTH"
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

whiptail --msgbox "Webmin is now installed, access it at https://$ADDRESS:10000..." "$WT_HEIGHT" "$WT_WIDTH"
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
  whiptail --msgbox "SSH server is now installed..." "$WT_HEIGHT" "$WT_WIDTH"
fi
}

################################ Install SSH client 4.4

do_install_SSH_client() {
  if [ $(dpkg-query -W -f='${Status}' openssh-client 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "OpenSSH client is already installed!"

else
  apt-get install openssh-client -y

  whiptail --msgbox "SSH client is now installed..." "$WT_HEIGHT" "$WT_WIDTH"
fi
}

################################ Change SSH port 4.5

do_ssh() {
PORT=$(whiptail --inputbox "New SSH port?" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
  	ufw allow "$PORT"/tcp
		ufw delete allow 22
  	sed -i "s|22|$PORT|g" /etc/ssh/sshd_config
    service openssh-server restart
  whiptail --msgbox "SSH port is now changed to $PORT and your firewall rules are updated..." "$WT_HEIGHT" "$WT_WIDTH"
}

################################ Install ClamAV 4.6

do_clamav() {
TOMAIL=$(whiptail --inputbox "What email should receive mail when system is infected?" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)

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

  whiptail --msgbox "ClamAV is now installed..." "$WT_HEIGHT" "$WT_WIDTH"
}

################################ Install Fail2Ban 4.7

do_fail2ban() {
  if [ $(dpkg-query -W -f='${Status}' fail2ban 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "Fail2ban server is already installed!"
else
  apt-get install fail2ban -y
  whiptail --msgbox "Fail2Ban is now installed..." "$WT_HEIGHT" "$WT_WIDTH"
fi
}

################################ Install Nginx 4.8

do_nginx() {
  if [ $(dpkg-query -W -f='${Status}' Nginx 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        echo "Nginx server is already installed!"
else
  whiptail --msgbox "In order for Nginx to work, apache2 needs to be shutdown. We will shutdown apache2 if needed..."
  service apache2 stop
  apt-get install nginx -y
  ufw allow 443/tcp
  ufw allow 80/tcp
  dpkg --configure --pending

  whiptail --msgbox "Nginx is now installed, also port 443 and 80 are open in the firewall..." "$WT_HEIGHT" "$WT_WIDTH"
fi
}

################################ Install  4.9



################################ Install NFS client 4.10

do_install_nfs_client() {
  if [ $(dpkg-query -W -f='${Status}' nfs-common 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "NFS client is already installed!"
else
  apt-get install nfs-common -y

  whiptail --msgbox 'Installed! Auto mount like this: echo "<nfs-server-IP>:/   /mount_point   nfs    auto  0  0" >> /etc/fstab' "$WT_HEIGHT" "$WT_WIDTH"
fi
}

################################ Install NFS server 4.11

do_install_nfs_server() {
  if [ $(dpkg-query -W -f='${Status}' nfs-kernel-server 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "NFS server is already installed!"

else
  apt-get install nfs-kernel-server -y
  ufw allow 2049

  whiptail --msgbox "Installed! You can broadcast your NFS server and set it up in webmin (when installed): https://$ADDRESS:10000" "$WT_HEIGHT" "$WT_WIDTH"
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
    whiptail --msgbox "AtoMiC-ToolKit is now installed, run it with: cd ~/AtoMiC-ToolKit && sudo bash setup.sh" "$WT_HEIGHT" "$WT_WIDTH"
    cd ~/AtoMiC-ToolKit
  	bash setup.sh
  	cd
}

################################ Install Plesk 4.14

do_plesk() {
  {
  i=1
  while read -r line; do
      i=$(( $i + 1 ))
      echo $i
  done < <(apt-get update)
} | whiptail --title "Progress" --gauge "Please wait while updating" 6 60 0

apt-get remove apparmor -y
wget -O - http://autoinstall.plesk.com/one-click-installer | sh
/etc/init.d/psa status
apt-get install mcrypt -y
apt-get install php-mcrypt -y
apt-get install php-ioncube-loader -y
apt-get install php-apc -y
apt-get install php-memcached memcached -y
apt-get install php-imap -y
phpenmod imap
do_update
service apache2 restart
}

################################ Install Network-manager 4.15

do_install_networkmanager() {
  if [ $(dpkg-query -W -f='${Status}' network-manager 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "network-manager is already installed!"
  else
        apt-get install network-manager -y
        whiptail --msgbox "Network-manager is now installed..." "$WT_HEIGHT" "$WT_WIDTH"
  fi
}

################################ Install 4.16



################################ Install OpenVpn 4.17

do_openvpn() {
if [ $(dpkg-query -W -f='${Status}' openvpn 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
  echo "OpenVpn is already installed!"
else
  apt-get install openvpn -y

  if [ $(dpkg-query -W -f='${Status}' network-manager-openvpn 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "network-manager-openvpn is already installed!"
  else
        apt-get install network-manager-openvpn -y
  fi

  whiptail --msgbox "OpenVpn is now installed..." "$WT_HEIGHT" "$WT_WIDTH"
fi
}

################################ Install Plex 4.18

do_install_plex() {
  if [ $(dpkg-query -W -f='${Status}' wget 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "Wget is already installed!"
else
  apt-get install wget -y
fi

if [ $(dpkg-query -W -f='${Status}' nfs-kernel-server 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
      echo "Git is already installed!"
else
apt-get install git -y
fi

  wget https://downloads.plex.tv/plex-media-server/1.1.3.2700-6f64a8d/plexmediaserver_1.1.3.2700-6f64a8d_amd64.deb -P /tmp/
	dpkg -i /tmp/plexmediaserver_1.1.3.2700-6f64a8d_amd64.deb
	cd /root

if 		[ -d /root/plexupdate ]; then
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
   echo "Already applied..."
else
	echo "bash /root/plexupdate/plexupdate.sh" >> /etc/cron.daily/plex.sh
	chmod 754 /etc/cron.daily/plex.sh
fi
whiptail --msgbox "Plex is now installed..." "$WT_HEIGHT" "$WT_WIDTH"
}

################################ Install VNC server 4.19

do_install_vnc() {
  if [ $(dpkg-query -W -f='${Status}' thightvncserver 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
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
  whiptail --msgbox "Firewall port updated (5901). Start: tightvncserver - Stop tightvncserver -kill :1" "$WT_HEIGHT" "$WT_WIDTH"
fi
}

################################ Install Zram-config 4.20

do_install_zram() {
if [ $(dpkg-query -W -f='${Status}' zram-config 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
      echo "Zram is already installed!"
else
apt-get install zram-config -y
whiptail --msgbox "Zram-config is now installed..." "$WT_HEIGHT" "$WT_WIDTH"
ASK_TO_REBOOT=1
do_finish
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
  } | whiptail --title "Progress" --gauge "Please wait while updating..." 6 60 0

# Install req packages
    {
    i=1
    while read -r line; do
        i=$(( i + 1 ))
        echo $i
    done < <(apt-get install virtualbox-dkms dkms build-essential linux-headers-generic linux-headers-$(uname -r) virtualbox-5.1 -y)
  } | whiptail --title "Progress" --gauge "Please wait while installing the required packages..." 6 60 0

sudo modprobe vboxdrv

whiptail --msgbox "Virtualbox is now installed..." "$WT_HEIGHT" "$WT_WIDTH"
}

################################ Install virtualbox extension pack 4.22

do_vboxextpack() {
wget http://download.virtualbox.org/virtualbox/5.1.4/Oracle_VM_VirtualBox_Extension_Pack-5.1.4-110228.vbox-extpack -P "$SCRIPTS"/
vboxmanage extpack install "$SCRIPTS"/Oracle_VM_VirtualBox_Extension_Pack-5.1.4-110228.vbox-extpack

whiptail --msgbox "Virtualbox extension pack is installed..." "$WT_HEIGHT" "$WT_WIDTH"
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

whiptail --msgbox "Virtualbox guest additions are now installed, make sure to reboot..." "$WT_HEIGHT" "$WT_WIDTH"
ASK_TO_REBOOT=1
do_finish
}

################################################ Firewall 5

do_firewall() {
  FUN=$(whiptail  --backtitle "Firewall" --title "Tech and Tool - https://www.techandme.se" --menu "Firewall options" "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" --cancel-button Back --ok-button Select \
    "0 Enable Firewall" "" \
    "1 Disable Firewall" "" \
    "2 Show current rules" "" \
    "3 Allow user defined" "" \
    "33 Deny user defined" "" \
    "4 Reset Firewall" "Be carefull only do this if you know what you're doing" \
    "5 Allow port Multiple" "Teamspeak" \
    "6 Allow port 32400" "Plex" \
    "7 Allow port 8989" "Sonarr" \
    "8 Allow port 5050" "Couchpotato" \
    "9 Allow port 8181" "Headphones" \
    "10 Allow port 8085" "HTPC Manager" \
    "11 Allow port 8080" "Mylar" \
    "12 Allow port 10000" "Webmin" \
    "13 Allow port 8080" "Sabnzbdplus" \
    "14 Allow port 9090" "Sabnzbdplus https" \
    "15 Allow port 2049" "NFS" \
    "16 Deny port Multiple" "Teamspeak" \
    "17 Deny port 32400" "Plex" \
    "18 Deny port 8989" "Sonarr" \
    "19 Deny port 5050" "Couchpotato" \
    "20 Deny port 8181" "Headphones" \
    "21 Deny port 8085" "HTPC Manager" \
    "22 Deny port 8080" "Mylar" \
    "23 Deny port 10000" "Webmin" \
    "24 Deny port 8080" "Sabnzbdplus" \
    "25 Deny port 9090" "Sabnzbdplus https" \
    "26 Deny port 2049" "NFS" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      0\ *) do_ufw_enable ;;
      1\ *) do_ufw_disable ;;
      2\ *) do_ufw_status ;;
      3\ *) do_ufw_allow ;;
      33\ *) do_ufw_deny ;;
      4\ *) do_ufw_reset ;;
      5\ *) do_allow_teamspeak ;;
      6\ *) do_allow_32400 ;;
      7\ *) do_allow_8989 ;;
      8\ *) do_allow_5050 ;;
      9\ *) do_allow_8181 ;;
      10\ *) do_allow_8085 ;;
      11\ *) do_allow_mylar ;;
      12\ *) do_allow_10000 ;;
      13\ *) do_allow_8080 ;;
      14\ *) do_allow_9090 ;;
      15\ *) do_allow_2049 ;;
      16\ *) do_deny_teamspeak ;;
      17\ *) do_deny_32400 ;;
      18\ *) do_deny_8989 ;;
      19\ *) do_deny_5050 ;;
      20\ *) do_deny_8181 ;;
      21\ *) do_deny_8085 ;;
      22\ *) do_deny_mylar ;;
      23\ *) do_deny_10000 ;;
      24\ *) do_deny_8080 ;;
      25\ *) do_deny_9090 ;;
      26\ *) do_deny_2049 ;;
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
#ufw reset << EOF
#y
#EOF
ufw enable
ufw default deny incoming
ufw status
sleep 2
whiptail --msgbox "Firewall is now enabled..." "$WT_HEIGHT" "$WT_WIDTH"
}
######Firewall#######
do_ufw_disable() {
ufw disable
ufw status
sleep 2
whiptail --msgbox "Firewall is now disabled, you are at risk..." "$WT_HEIGHT" "$WT_WIDTH"
}
######Firewall#######
do_ufw_status() {
STATUS=$(ufw status)
whiptail --msgbox "$STATUS" "$WT_HEIGHT" "$WT_WIDTH"
}
######Firewall#######
do_ufw_allow() {
PORT=$(whiptail --inputbox "What port or range should we allow? Type: man ufw for details on the firewall." "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
ufw allow $PORT
ufw status
sleep 2
}
######Firewall#######
do_ufw_deny() {
PORT=$(whiptail --inputbox "What port or range should we deny? Type: man ufw for details on the firewall." "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
ufw allow $PORT
ufw status
sleep 2
}
######Firewall#######
do_ufw_reset() {
ufw reset << EOF
y
EOF
whiptail --msgbox "Firewall is now reset please set your rules..." "$WT_HEIGHT" "$WT_WIDTH"
}
######Firewall#######
do_allow_32400() {
ufw allow 32400
ufw status
sleep 2
}
######Firewall#######
do_allow_10000() {
ufw allow 10000
ufw status
sleep 2
}
######Firewall#######
do_allow_5050() {
ufw allow 5050
ufw status
sleep 2
}
######Firewall#######
do_allow_9090() {
ufw allow 9090
ufw status
sleep 2
}
######Firewall#######
do_allow_8080() {
ufw allow 8080
ufw status
sleep 2
}
######Firewall#######
do_allow_8989() {
ufw allow 8989
ufw status
sleep 2
}
######Firewall#######
do_allow_8181() {
ufw allow 8181
ufw status
sleep 2
}
######Firewall#######
do_allow_8085() {
ufw allow 8085
ufw status
sleep 2
}
######Firewall#######
do_allow_mylar() {
ufw allow 8080
ufw status
sleep 2
}
######Firewall#######
do_allow_2049() {
ufw allow 2049
ufw status
sleep 2
}
######Firewall#######
do_allow_teamspeak() {
ufw allow 9987
ufw allow 10011
ufw allow 30033
ufw status
sleep 2
}
######Firewall#######
do_deny_32400() {
ufw deny 32400
ufw status
sleep 2
}
######Firewall#######
do_deny_10000() {
ufw deny 10000
ufw status
sleep 2
}
######Firewall#######
do_deny_5050() {
ufw deny 5050
ufw status
sleep 2
}
######Firewall#######
do_deny_9090() {
ufw deny 9090
ufw status
sleep 2
}
######Firewall#######
do_deny_8080() {
ufw deny 8080
ufw status
sleep 2
}
######Firewall#######
do_deny_8989() {
ufw deny 8989
ufw status
sleep 2
}
######Firewall#######
do_deny_8181() {
ufw deny 8181
ufw status
sleep 2
}
######Firewall#######
do_deny_8085() {
ufw deny 8085
ufw status
sleep 2
}
######Firewall#######
do_deny_mylar() {
ufw deny 8080
ufw status
sleep 2
}
######Firewall#######
do_deny_2049() {
ufw deny 2049
ufw status
sleep 2
}
######Firewall#######
do_deny_teamspeak() {
ufw deny 9987
ufw deny 10011
ufw deny 30033
ufw status
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
    done < <(sleep 1 && apt-get autoclean)
  } | whiptail --title "Progress" --gauge "Please wait while auto cleaning" 6 60 0

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(sleep 1 && apt-get autoremove -y)
  } | whiptail --title "Progress" --gauge "Please wait while auto removing un-needed dependancies" 6 60 0

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get update)
  } | whiptail --title "Progress" --gauge "Please wait while updating" 6 60 0

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(sleep 1 && apt-get upgrade -y)
  } | whiptail --title "Progress" --gauge "Please wait while upgrading" 6 60 0

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(sleep 1 && apt-get install -fy)
  } | whiptail --title "Progress" --gauge "Please wait while forcing install of dependancies" 6 60 0

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(sleep 1 && apt-get dist-upgrade -y)
  } | whiptail --title "Progress" --gauge "Please wait while doing dist-upgrade" 6 60 0

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(aptitude full-upgrade -y)
  } | whiptail --title "Progress" --gauge "Please wait while upgrading with aptitude" 6 60 0

	dpkg --configure --pending

  if [ -f "$SCRIPTS"/techandtool.sh ]; then
          rm "$SCRIPTS"/techandtool.sh
  fi

  if [ -f /usr/sbin/techandtool ]; then
          rm /usr/sbin/techandtool
  fi
          mkdir -p "$SCRIPTS"
          wget -q https://github.com/ezraholm50/techandtool/raw/master/techandtool.sh -P "$SCRIPTS"
          cp "$SCRIPTS"/techandtool.sh /usr/sbin/techandtool
          chmod +x /usr/sbin/techandtool

          if [ -f "$SCRIPTS"/techandtool.sh ]; then
                  rm "$SCRIPTS"/techandtool.sh
          fi

          exec techandtool
}

################################################ Reboot 7

do_reboot() {
  whiptail --yesno "Would you like to reboot now?" "$WT_HEIGHT" "$WT_WIDTH"
  if [ $? -eq 0 ]; then # yes
    reboot
  fi
}

################################################ Poweroff 8

do_poweroff() {
    whiptail --yesno "Would you like to shutdown now?" "$WT_HEIGHT" "$WT_WIDTH"
    if [ $? -eq 0 ]; then # yes
      shutdown now
    fi
}

################################################ About 9

do_about() {
  whiptail --msgbox "\
This tool is created by techandme.se for less skilled linux terminal users.

It makes it easy just browsing the menu and installing or using system tools.

Please post requests (with REQUEST in title) here: https://github.com/ezraholm50/techandtool/issues

Note that this tool is tested on Ubuntu 16.04 (should work on debian)

Visit https://www.techandme.se for awsome free virtual machines,
Nextcloud, ownCloud, Teamspeak, Wordpress, Minecraft etc.\
" "$WT_HEIGHT" "$WT_WIDTH"
}

################################################ System info 10

do_system() {
if [ $(dpkg-query -W -f='${Status}' landscape-common 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
        echo "Landscape-common is already installed..."
else
  {
   i=1
   while read -r line; do
       i=$(( $i + 1 ))
       echo $i
   done < <(apt-get update && apt-get install landscape-common -y)
 } | whiptail --title "Progress" --gauge "Please wait while installing landscape..." 6 60 0
fi

  HEADER=$(bash /etc/update-motd.d/00-header)
  SYSINFO=$(landscape-sysinfo)
  UPDATESAV=$(bash /etc/update-motd.d/90-updates-available)
  FSCK=$(bash /etc/update-motd.d/98-fsck-at-reboot)
  REBOOT=$(bash /etc/update-motd.d/98-reboot-required )
  RELEASE=$(bash /etc/update-motd.d/91-release-upgrade)

  whiptail --title "System Information - Scroll down for more info" --msgbox "\
  $HEADER\

  $SYSINFO\

  $UPDATESAV
  $FSCK
  $REBOOT
  $RELEASE\
  " "$WT_HEIGHT" "$WT_WIDTH" --scrolltext
}

################################################ Main menu 11

calc_wt_size
while true; do
  FUN=$(whiptail --backtitle "Tech and Tool main menu" --title "Tech and Tool - https://www.techandme.se" --menu "Tech and tool" "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" --cancel-button Finish --ok-button Select \
    "1 Tech and Me" "Install various VM's" \
    "2 Tools" "Various tools" \
    "3 Packages" "Install various software packages" \
    "4 Firewall" "Enable/disable and open/close ports" \
    "5 Raspberry" "Specific tools for RPI 1, 2, 3 and zero" \
    "6 Update & upgrade" "Updates and upgrades packages and get the latest version of this tool" \
    "7 Reboot" "Reboots your machine" \
    "8 Shutdown" "Shutdown your machine" \
    "9 About Tech and Tool" "Information about this tool" \
    "10 System Information" "Show available updates, releases and sys info" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
	do_finish
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) do_techandme ;;
      2\ *) do_tools ;;
      3\ *) do_install ;;
      4\ *) do_firewall ;;
      5\ *) do_Raspberry ;;
      6\ *) do_update ;;
      7\ *) do_reboot ;;
      8\ *) do_poweroff ;;
      9\ *) do_about ;;
      10\ *) do_system ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
 else
   exit 1
  fi
done
