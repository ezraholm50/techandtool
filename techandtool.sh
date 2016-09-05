#!/bin/sh
#
# Tech and Me, 2016 - www.techandme.se
# Whiptail menu to install various Nextcloud app and do other useful stuf.
##### Index ######
#- 1 Variable
#- 1.1 Network
#- 1.2
#- 1.3
#- 1.4 Whiptail
#- 1.5 Root check
#- 1.6
#- 1.7
#- 1.8
#- 1.9
#- 2 Apps
#- 2.1 Collabora
#- 2.2 Spreed-webrtc
#- 2.3 Gpxpod
#- 2.4
#- 2.5
#- 2.6
#- 3 Tools
#- 3.1 Show LAN details
#- 3.2 Show WAN details
#- 3.3 Change Hostname
#- 3.4 Internationalisation
#- 3.5 Connect to WLAN
#- 3.6 Raspberry specific
#- 3.61 Resize root fs
#- 3.62 External USB HD
#- 3.63 RPI-update
#- 3.64 Raspi-config
#- 3.7 Show folder size
#- 3.8 Show folder content with permissions
#- 3.9 Show connected devices
#- 3.10 Show disks usage
#- 3.11 Show system performance
#- 3.12 Disable IPV6
#- 3.13 Find string in files
#- 3.14 Reboot on out of memory
#- 4 About this tool
#- 5 Tech and Tool

################################################ Variable 1
################################ Network 1.1

IFCONFIG=$(ifconfig)
IP="/sbin/ip"
IFACE=$($IP -o link show | awk '{print $2,$9}' | grep "UP" | cut -d ":" -f 1)
INTERFACES="/etc/network/interfaces"
ADDRESS=$($IP route get 1 | awk '{print $NF;exit}')
NETMASK=$(ifconfig "$IFACE" | grep Mask | sed s/^.*Mask://)
GATEWAY=$($IP route | awk '/default/ { print $3 }')

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

	if [ $(dpkg-query -W -f='${Status}' whiptail 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        sleep 0

else

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get install whiptail -y)
    } | whiptail --title "Progress" --gauge "Please wait while installing Whiptail" 6 60 0

fi

################################################ Check if root 1.6

if [ "$(whoami)" != "root" ]; then
        whiptail --msgbox "Sorry you are not root. You must type: sudo bash techandtool.sh" 20 60 1
        exit
fi

################################################ Locations 1.8

REPO="https://github.com/ezraholm50/vm/raw/master"
SCRIPTS="/var/scripts"

################################################ Apps 2

do_apps() {
  FUN=$(whiptail --title "Tech and Tool - https://www.techandme.se" --menu "Apps" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT \
    "T1 Collabora" "Docker" \
    "T2 Spreed-webrtc" "Spreedme" \
    "T3 Gpxpod" "" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
    return 0
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      T1\ *) do_collabora ;;
      T2\ *) do_spreed_webrtc ;;
      T3\ *) do_gpxpod ;;
      *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

################################ Collabora 2.1

do_collabora() {
HTTPS_EXIST="/etc/apache2/sites-available/$EXISTINGDOMAIN"
HTTPS_CONF="/etc/apache2/sites-available/$EDITORDOMAIN"
DOMAIN=$(whiptail --title "Techandme.se Collabora" --inputbox "Nextcloud url, make sure it looks like this: cloud\.yourdomain\.com" 10 60 cloud\.yourdomain\.com 3>&1 1>&2 2>&3)
DOMAIN1=$(whiptail --title "Techandme.se Collabora" --inputbox "Nextcloud url, now make sure it look normal" 10 60 cloud.yourdomain.com 3>&1 1>&2 2>&3)
EDITORDOMAIN=$(whiptail --title "Techandme.se Collabora" --inputbox "Collabora subdomain eg: office.yourdomain.com" 10 60 3>&1 1>&2 2>&3)
EXISTINGDOMAIN=$(whiptail --title "Techandme.se Collabora" --inputbox "Existing domain VHOST" 10 60 nextcloud_ssl_domain_self_signed.conf 3>&1 1>&2 2>&3)

# Message
whiptail --msgbox "Please before you start make sure port 443 is directly forwarded to this machine or open!" 20 60 2

# Update & upgrade
    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get update && apt-get upgrade -y && apt-get -f install -y)
    } | whiptail --title "Progress" --gauge "Please wait while updating repo's" 6 60 0

# Check if docker is installed

	if [ $(dpkg-query -W -f='${Status}' docker.io 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        sleep 0

else
    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get install docker.io -y)
    } | whiptail --title "Progress" --gauge "Please wait while installing docker" 6 60 0
fi

# Install Collabora docker

docker pull collabora/code
docker run -t -d -p 127.0.0.1:9980:9980 -e "domain=$DOMAIN" --restart always --cap-add MKNOD collabora/code

# Install Apache2

	if [ $(dpkg-query -W -f='${Status}' apache2 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        sleep 0

else

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get install apache2 -y)
    } | whiptail --title "Progress" --gauge "Please wait while installing Apache2" 6 60 0

fi

# Enable Apache2 module's

a2enmod proxy
a2enmod proxy_wstunnel
a2enmod proxy_http
a2enmod ssl

# Create Vhost for Collabora online in Apache2

if [ -f "$HTTPS_CONF" ];
then
        echo "Virtual Host exists"
else

	touch "$HTTPS_CONF"
        cat << HTTPS_CREATE > "$HTTPS_CONF"
<VirtualHost *:443>
  ServerName $EDITORDOMAIN

  # SSL configuration, you may want to take the easy route instead and use Lets Encrypt!
  SSLEngine on
  SSLCertificateFile /path/to/signed_certificate
  SSLCertificateChainFile /path/to/intermediate_certificate
  SSLCertificateKeyFile /path/to/private/key
  SSLProtocol             all -SSLv2 -SSLv3
  SSLCipherSuite ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA:ECDHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES256-SHA:ECDHE-ECDSA-DES-CBC3-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES128-GCM-SHA256:AES256-GCM-SHA384:AES128-SHA256:AES256-SHA256:AES128-SHA:AES256-SHA:DES-CBC3-SHA:!DSS
  SSLHonorCipherOrder     on

  # Encoded slashes need to be allowed
  AllowEncodedSlashes On

  # Container uses a unique non-signed certificate
  SSLProxyEngine On
  SSLProxyVerify None
  SSLProxyCheckPeerCN Off
  SSLProxyCheckPeerName Off

  # keep the host
  ProxyPreserveHost On

  # static html, js, images, etc. served from loolwsd
  # loleaflet is the client part of LibreOffice Online
  ProxyPass           /loleaflet https://127.0.0.1:9980/loleaflet retry=0
  ProxyPassReverse    /loleaflet https://127.0.0.1:9980/loleaflet

  # WOPI discovery URL
  ProxyPass           /hosting/discovery https://127.0.0.1:9980/hosting/discovery retry=0
  ProxyPassReverse    /hosting/discovery https://127.0.0.1:9980/hosting/discovery

  # Main websocket
  ProxyPass   /lool/ws      wss://127.0.0.1:9980/lool/ws

  # Admin Console websocket
  ProxyPass   /lool/adminws wss://127.0.0.1:9980/lool/adminws

  # Download as, Fullscreen presentation and Image upload operations
  ProxyPass           /lool https://127.0.0.1:9980/lool
  ProxyPassReverse    /lool https://127.0.0.1:9980/lool
</VirtualHost>
HTTPS_CREATE

if [ -f "$HTTPS_CONF" ];
then
        echo "$HTTPS_CONF was successfully created"
        sleep 2
else
	echo "Unable to create vhost, exiting..."
	exit
fi

fi

# Restart Apache2
service apache2 restart

# Firewall -- not needed for it to work
#if (whiptail --title "Test Yes/No Box" --yes-button "Firewall" --no-button "No Firewall"  --yesno "Do you have a firewall enabled?" 10 60) then
#    echo "You chose yes..."

#if (whiptail --title "Test Yes/No Box" --yes-button "UFW" --no-button "IPtables"  --yesno "Do you have UFW or IPtables enabled?" 10 60) then
#    echo "You chose UFW..."
#        sudo ufw allow 9980
#else
#    echo "You chose IPtables... Please file a PR to add a rule for IPtables."
#fi

#else
#    echo "You chose no, it is highly recommended that you use a firewall! Enable it by typing: sudo ufw enable && sudo ufw allow 9980."
#fi

# Let's Encrypt
##### START FIRST TRY
# Stop Apache to aviod port conflicts
        a2dissite 000-default.conf
        sudo service apache2 stop
# Check if $letsencryptpath exist, and if, then delete.
if [ -d "$letsencryptpath" ]; then
  	rm -R "$letsencryptpath"
fi
# Generate certs
	cd "$dir_before_letsencrypt"
	git clone https://github.com/letsencrypt/letsencrypt
	cd "$letsencryptpath"
        ./letsencrypt-auto certonly --standalone -d "$EDITORDOMAIN" -d "$DOMAIN1"
# Use for testing
#./letsencrypt-auto --apache --server https://acme-staging.api.letsencrypt.org/directory -d EXAMPLE.COM
# Activate Apache again (Disabled during standalone)
        service apache2 start
        a2ensite 000-default.conf
        service apache2 reload
# Check if $certfiles exists
if [ -d "$certfiles" ]; then
# Activate new config
	sed -i "s|SSLCertificateKeyFile /path/to/private/key|SSLCertificateKeyFile $certfiles/$EDITORDOMAIN/privkey.pem|g"
	sed -i "s|SSLCertificateFile /path/to/signed_certificate|SSLCertificateFile $certfiles/$EDITORDOMAIN/cert.pem|g"
	sed -i "s|SSLCertificateChainFile /path/to/intermediate_certificate|SSLCertificateChainFile $certfiles/$EDITORDOMAIN/chain.pem|g"
        service apache2 restart
        bash /var/scripts/test-new-config.sh
# Message
whiptail --msgbox "\
Succesfully installed Collabora online docker, now please head over to your Nextcloud apps and admin panel
and enable the Collabora online connector app and change the URL to whatever subdomain you choose to run Collabora on.\
" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT

	exit 0
else
        echo -e "\e[96m"
        echo -e "It seems like no certs were generated, we do three more tries."
        echo -e "\e[32m"
        read -p "Press any key to continue... " -n1 -s
        echo -e "\e[0m"
fi

##### START SECOND TRY
# Check if $letsencryptpath exist, and if, then delete.
	if [ -d "$letsencryptpath" ]; then
  	rm -R "$letsencryptpath"
fi

# Generate certs
	cd "$dir_before_letsencrypt"
	git clone https://github.com/letsencrypt/letsencrypt
	cd "$letsencryptpath"
	./letsencrypt-auto -d "$EDITORDOMAIN" -d "$DOMAIN1"

# Check if $certfiles exists
if [ -d "$certfiles" ]; then
# Activate new config
	sed -i "s|SSLCertificateKeyFile /path/to/private/key|SSLCertificateKeyFile $certfiles/$EDITORDOMAIN/privkey.pem|g"
	sed -i "s|SSLCertificateFile /path/to/signed_certificate|SSLCertificateFile $certfiles/$EDITORDOMAIN/cert.pem|g"
	sed -i "s|SSLCertificateChainFile /path/to/intermediate_certificate|SSLCertificateChainFile $certfiles/$EDITORDOMAIN/chain.pem|g"
##### original vhost also change the newly made certs

	service apache2 restart
	bash /var/scripts/test-new-config.sh
# Message
whiptail --msgbox "Succesfully installed Collabora online docker, now please head over to your Nextcloud apps and admin paneland enable the Collabora online connector app and change the URL to whatever subdomain you choose to run Collabora on." $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT

        exit 0
else
	echo -e "\e[96m"
	echo -e "It seems like no certs were generated, something went wrong"
	echo -e "\e[32m"
	read -p "Press any key to continue... " -n1 -s
	echo -e "\e[0m"
fi

exit 0
}

################################ Spreed-webrtc 2.2

do_spreed_webrtc() {
ENCRYPTIONSECRET=$(openssl rand -hex 32)
SESSIONSECRET=$(openssl rand -hex 32)
SERVERTOKEN=$(openssl rand -hex 32)
SHAREDSECRET=$(openssl rand -hex 32)
DOMAIN=$(whiptail --title "Techandme.se Collabora online installer" --inputbox "Nextcloud url, make sure it looks like this: https://cloud.nextcloud.com" 10 60 https://yourdomain.com 3>&1 1>&2 2>&3)
NCDIR=$(whiptail --title "Nextcloud directory" --inputbox "If you're not sure use the default setting" 10 60 /var/www/nextcloud 3>&1 1>&2 2>&3)
WEB=$(whiptail --title "What webserver do you run" --inputbox "If you're not sure use the default setting" 10 60 apache2 3>&1 1>&2 2>&3)
SPREEDDOMAIN=$(whiptail --title "Spreed domain" --inputbox "Leave empty for autodiscovery" 10 60 3>&1 1>&2 2>&3)
SPREEDPORT=$(whiptail --title "Spreed port" --inputbox "If you're not sure use the default setting" 10 60 8443 3>&1 1>&2 2>&3)
VHOST443=$(whiptail --title "Vhost 443 file location" --inputbox "If you're not sure use the default setting" 10 60 /etc/"$WEB"/sites-available/nextcloud_ssl_domain_self_signed.conf 3>&1 1>&2 2>&3)
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
  FUN=$(whiptail --title "Tech and Tool - https://www.techandme.se" --menu "Tools" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT \
    "T1 Show LAN IP, Gateway, Netmask" "Ifconfig" \
    "T2 Show WAN IP" "External IP address" \
    "T3 Change Hostname" "" \
    "T4 Internationalisation Options" "Change language, time, date and keyboard layout" \
    "T5 Connect to WLAN" "Please have a wifi dongle/card plugged in before start" \
    "T6 Show folder size" ""\
    "T7 Show folder conten" "with permissions" \
    "T8 Show connected devices" "blkid" \
    "T9 Show disks usage" "df -h" \
    "T10 Show system performance" "HTOP" \
    "T11 Disable IPV6" "Via sysctl.conf" \
    "T12 Find text" "In a given directory" \
    "T13 OOM fix" "Auto reboot on out of memory errors" \
    "T14 Install virtualbox" \
    "T15 Install virtualbox extension pack"
    "T16 Install virtualbox guest additions"
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
      T14\ *) do_virtualbox ;;
      T15\ *) do_vboxextpack ;;
      T16\ *) do_vboxguestadd ;;
    *) whiptail --msgbox "Programmer error: unrecognized option" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $FUN" 20 60 1
  fi
}

################################ Network details 3.1

do_ifconfig() {
whiptail --msgbox "\
Interface: $IFACE
LAN IP: $ADDRESS
Netmask: $NETMASK
Gateway: $GATEWAY\
" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT
}

################################ Wan IP 3.2

do_wan_ip() {
  WAN=$(wget -qO- http://ipecho.net/plain ; echo)
  whiptail --msgbox "WAN IP: $WAN" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT
}

################################ Hostname 3.3

do_change_hostname() {
  whiptail --msgbox "\
Please note: RFCs mandate that a hostname's labels \
may contain only the ASCII letters 'a' through 'z' (case-insensitive),
the digits '0' through '9', and the hyphen.
Hostname labels cannot begin or end with a hyphen.
No other symbols, punctuation characters, or blank spaces are permitted.\
" 20 70 1

  CURRENT_HOSTNAME=$(cat < /etc/hostname | tr -d " \t\n\r")
  NEW_HOSTNAME=$(whiptail --inputbox "Please enter a hostname" 20 60 "$CURRENT_HOSTNAME" 3>&1 1>&2 2>&3)
  if [ $? -eq 0 ]; then
    echo "$NEW_HOSTNAME" > /etc/hostname
    sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    ASK_TO_REBOOT=1
  fi
}

################################ Internationalisation 3.4

do_internationalisation_menu() {
  FUN=$(whiptail --title "Tech and Tool - https://www.techandme.se" --menu "Internationalisation Options" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Back --ok-button Select \
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
whiptail --yesno "Do you want to connect to wifi? Its recommended to use a wired connection for your NextBerry server!" --yes-button "Wireless" --no-button "Wired" 20 60 1
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
  FUN=$(whiptail --title "Tech and Tool - https://www.techandme.se" --menu "Raspberry" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT \
    "R1 Resize SD" "" \
    "R2 External USB" "Use an USB HD/SSD as root" \
    "R3 RPI-update" "Update the RPI firmware and kernel" \
    "R4 Raspi-config" "Set various settings, not all are tested! Already overclocked!"
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
  ASK_TO_REBOOT=1

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
  if [ "$INTERACTIVE" = True ]; then
    whiptail --msgbox "Root partition has been resized.\nThe filesystem will be enlarged upon the next reboot" 20 60 2
  fi
}

##################### External USB 3.62

do_external_usb() {
	sleep 1
}

##################### RPI-update 3.63

do_rpi_update() {
	    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(rpi-update)
    } | whiptail --title "Progress" --gauge "Please wait while updating your RPI firmware and kernel" 6 60 0
}

##################### Raspi-config 3.64

do_raspi_config() {
	echo
	echo "Not configured yet, sorry..."
	echo
	sleep 2
}

################################ Show folder size 3.7

do_foldersize() {

	if [ $(dpkg-query -W -f='${Status}' ncdu 2>/dev/null | grep -c "ok installed") -eq 1 ];
then
        ncdu /
else
    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <(apt-get install ncdu -y)
    } | whiptail --title "Progress" --gauge "Please wait while installing ncdu" 6 60 0

	ncdu /

fi
}

################################ Show folder content and permissions 3.8

do_listdir() {
	LISTDIR=$(whiptail --title "Directory to list? Eg. /mnt/yourfolder" --inputbox "Navigate with TAB to hit ok to enter input" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT 3>&1 1>&2 2>&3)
	LISTDIR1=$(ls -la "$LISTDIR")
	whiptail --msgbox "$LISTDIR1" 30 $WT_WIDTH $WT_MENU_HEIGHT
}

################################ Show connected devices 3.9

do_blkid() {
  BLKID=$(blkid)
  whiptail --msgbox "$BLKID" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT
}

################################ Show disk usage 3.10

do_df() {
  DF=$(df -h)
  whiptail --msgbox "$DF" 20 $WT_WIDTH $WT_MENU_HEIGHT
}

################################ Show system performance 3.11

do_htop() {
#	if [ $(dpkg-query -W -f='${Status}' htop 2>/dev/null | grep -c "ok installed") -eq 1 ];
#then
	apt-get install htop
        htop
#else
#
#    {
#    i=1
#    while read -r line; do
#        i=$(( $i + 1 ))
#        echo $i
#    done < <(apt-get install htop -y)
#    } | whiptail --title "Progress" --gauge "Please wait while installing htop" 6 60 0
#
#fi
#	htop
}

################################ Disable IPV6 3.12

do_disable_ipv6() {

 if grep -q net.ipv6.conf.all.disable_ipv6 = 1 "/etc/sysctl.conf"; then
   sleep 0
 else
 echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
 fi

 if grep -q net.ipv6.conf.default.disable_ipv6 = 1 "/etc/sysctl.conf"; then
   sleep 0
 else
 echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
 fi

  if grep -q net.ipv6.conf.lo.disable_ipv6 = 1 = 1 "/etc/sysctl.conf"; then
   sleep 0
 else
 echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
 fi

 echo
 sysctl -p
 echo

whiptail --msgbox "IPV6 is now disabled..." 10 60 1
}

################################ Find string text 3.13

do_find_string() {
        STRINGTEXT=$(whiptail --inputbox "Text that you want to search for? eg. ip mismatch: 192.168.1.133" 10 60 3>&1 1>&2 2>&3)
        STRINGDIR=$(whiptail --inputbox "Directory you want to search in? eg. / for whole system or /home" 10 60 3>&1 1>&2 2>&3)
        STRINGCMD=$(grep -Rl "$STRINGTEXT" "$STRINGDIR")
        whiptail --msgbox "$STRINGCMD" $WT_WIDTH $WT_MENU_HEIGHT
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

whiptail --msgbox "System will reboot on out of memory error..." 10 60 1
}

################################ Install virtualbox 3.15

do_virtualbox() {
echo "deb http://download.virtualbox.org/virtualbox/debian xenial contrib" >> /etc/apt/sources.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
sudo aptitude update
sudo aptitude install virtualbox-dkms dkms build-essential linux-headers-generic linux-headers-$(uname -r) virtualbox-5.1 -y
sudo modprobe vboxdrv

whiptail --msgbox "Virtualbox is now installed..." 10 60 1
}

################################ Install virtualbox extension pack 3.16

do_vboxextpack() {
wget http://download.virtualbox.org/virtualbox/5.1.4/Oracle_VM_VirtualBox_Extension_Pack-5.1.4-110228.vbox-extpack -P /var/scripts/
vboxmanage extpack install /var/scripts/http://download.virtualbox.org/virtualbox/5.1.4/Oracle_VM_VirtualBox_Extension_Pack-5.1.4-110228.vbox-extpack

whiptail --msgbox "Virtualbox extension pack is installed..." 10 60 1
}

################################ Install virtualbox guest additions

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

whiptail --msgbox "Virtualbox guest additions are now installed, make sure to reboot..." 10 60 1
}

################################
################################
################################
################################
################################
################################# Update

do_update() {

   {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <( apt-get autoclean )
    } | whiptail --title "Progress" --gauge "Please wait while auto cleaning" 6 60 0

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <( apt-get autoremove -y )
    } | whiptail --title "Progress" --gauge "Please wait while auto removing unneeded dependancies " 6 60 0

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <( apt-get update )
    } | whiptail --title "Progress" --gauge "Please wait while updating " 6 60 0


    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <( apt-get upgrade -y )
    } | whiptail --title "Progress" --gauge "Please wait while ugrading " 6 60 0

    {
    i=1
    while read -r line; do
        i=$(( $i + 1 ))
        echo $i
    done < <( apt-get install -fy )
    } | whiptail --title "Progress" --gauge "Please wait while forcing install of dependancies " 6 60 0

	dpkg --configure --pending

	mkdir -p /var/scripts

	if [ -f /var/scripts/techandtool.sh ]
then
        rm /var/scripts/techandtool.sh
fi
        wget https://github.com/ezraholm50/vm/raw/master/static/techandtool.sh -P /var/scripts
	exit | bash /var/scripts/techandtool.sh
}

################################################ About

do_about() {
  whiptail --msgbox "\
This tool is created by techandme.se for less skilled linux terminal users.
It makes it easy just browsing the menu and installing or using system tools. Please post requests or suggestions here:
lINK TO FOLLOW!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Visit https://www.techandme.se for awsome free virtual machines,
Nextcloud, ownCloud, Teamspeak, Wordpress etc.\
" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT
}

################################################ Interactive use loop

calc_wt_size
while true; do
  FUN=$(whiptail --title "https://www.techandme.se" --menu "Multi Installer" $WT_HEIGHT $WT_WIDTH $WT_MENU_HEIGHT --cancel-button Finish --ok-button Select \
    "1 Apps" "Nextcloud" \
    "2 Tools" "Various tools" \
    "3 Update & upgrade" "Updates and upgrades packages and get the latest version of this tool" \
    "4 Reboot" "Reboots your machine" \
    "5 Shutdown" "Shutdown your machine" \
    "6 About Tech and Tool" "Information about this tool" \
    3>&1 1>&2 2>&3)
  RET=$?
  if [ $RET -eq 1 ]; then
	do_finish
  elif [ $RET -eq 0 ]; then
    case "$FUN" in
      1\ *) do_apps ;;
      2\ *) do_tools;;
      3\ *) do_update ;;
      4\ *) do_reboot ;;
      5\ *) do_poweroff ;;
      6\ *) do_about ;;
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
