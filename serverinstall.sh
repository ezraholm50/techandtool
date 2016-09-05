#!/bin/bash
# host
sudo apt-get autoclean
sudo apt-get autoremove
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get -f install
sudo apt-get dist-upgrade -y
sudo apt-get install aptitude
aptitude update
aptitude full-upgrade -y
aptitude install build-essential linux-headers-generic linux-headers-$(uname -r) -y
sudo apt-get autoclean
sudo apt-get autoremove
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get -f install
sudo apt-get dist-upgrade -y
sudo apt-get install aptitude
aptitude update
aptitude full-upgrade -y
sudo apt-get install update-manager-core -y
nano /etc/update-manager/release-upgrades
sudo do-release-upgrade -d

sudo apt-get autoclean
sudo apt-get autoremove
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get -f install
sudo apt-get dist-upgrade -y
sudo apt-get install aptitude
aptitude update
aptitude full-upgrade -y
aptitude install build-essential linux-headers-generic linux-headers-$(uname -r) -y
sudo apt-get autoclean
sudo apt-get autoremove
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get -f install
sudo apt-get dist-upgrade -y
sudo apt-get install aptitude
aptitude update
aptitude full-upgrade -y

echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "vm.swappiness = 0" >> /etc/sysctl.conf
sudo sysctl -p
cat /proc/sys/net/ipv6/conf/all/disable_ipv6

mkdir /var/scripts
wget http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/current/images/netboot/mini.iso -P /var/scripts/

echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
cd /root
wget http://www.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc
apt-get update
apt-get install webmin -y

sudo apt-get purge virtualbox* dkms linux-headers-$(uname -r)
echo "deb http://download.virtualbox.org/virtualbox/debian xenial contrib" >> /etc/apt/sources.list
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
sudo aptitude update
sudo aptitude install virtualbox-dkms dkms build-essential linux-headers-generic linux-headers-$(uname -r) virtualbox-5.1 -y
sudo dpkg-reconfigure virtualbox-dkms
sudo modprobe vboxdrv
wget http://download.virtualbox.org/virtualbox/5.1.4/Oracle_VM_VirtualBox_Extension_Pack-5.1.4-110228.vbox-extpack -P /var/scripts/
vboxmanage

echo "# panic kernel on OOM" > /etc/sysctl.d/oom_reboot.conf
echo "vm.panic_on_oom=1" >> /etc/sysctl.d/oom_reboot.conf
echo "# reboot after 10 sec on panic" >> /etc/sysctl.d/oom_reboot.conf
echo "kernel.panic=10" >> /etc/sysctl.d/oom_reboot.conf
sysctl -p /etc/sysctl.d/oom_reboot.conf

echo "options timeout:1 rotate attempts:1" > /etc/resolvconf/resolv.conf.d/tail
echo "nameserver 8.8.8.8 #Google NS1" >> /etc/resolvconf/resolv.conf.d/tail
echo "nameserver 8.8.2.2 #Google NS2" >> /etc/resolvconf/resolv.conf.d/tail
echo "nameserver 208.67.222.222 #OpenDNS1" >> /etc/resolvconf/resolv.conf.d/tail
echo "#nameserver 208.67.220.220 #OpenDNS2" >> /etc/resolvconf/resolv.conf.d/tail


#!/bin/bash
# guest
sudo apt-get autoclean
sudo apt-get autoremove
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get -f install
sudo apt-get dist-upgrade -y
sudo apt-get install aptitude
aptitude update
aptitude full-upgrade -y

echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "vm.swappiness = 0" >> /etc/sysctl.conf
sudo sysctl -p
cat /proc/sys/net/ipv6/conf/all/disable_ipv6

echo "deb http://download.webmin.com/download/repository sarge contrib" >> /etc/apt/sources.list
cd /root
wget http://www.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc
apt-get update
apt-get install webmin -y

sudo apt-get install virtualbox-guest-additions-iso
mount /usr/share/virtualbox/VBoxGuestAdditions.iso /mnt
cd /mnt
./VBoxLinuxAdditions.run

echo "# panic kernel on OOM" > /etc/sysctl.d/oom_reboot.conf
echo "vm.panic_on_oom=1" >> /etc/sysctl.d/oom_reboot.conf
echo "# reboot after 10 sec on panic" >> /etc/sysctl.d/oom_reboot.conf
echo "kernel.panic=10" >> /etc/sysctl.d/oom_reboot.conf
sysctl -p /etc/sysctl.d/oom_reboot.conf

echo "options timeout:1 rotate attempts:1" > /etc/resolvconf/resolv.conf.d/tail
echo "nameserver 8.8.8.8 #Google NS1" >> /etc/resolvconf/resolv.conf.d/tail
echo "nameserver 8.8.2.2 #Google NS2" >> /etc/resolvconf/resolv.conf.d/tail
echo "nameserver 208.67.222.222 #OpenDNS1" >> /etc/resolvconf/resolv.conf.d/tail
echo "#nameserver 208.67.220.220 #OpenDNS2" >> /etc/resolvconf/resolv.conf.d/tail


# plesk
sudo apt-get remove apparmor -y
wget -O - http://autoinstall.plesk.com/one-click-installer | sh
/etc/init.d/psa status
apt-get install mcrypt -y
apt-get install php-mcrypt -y
apt-get install php-ioncube-loader -y
apt-get install php-apc -y
apt-get install php-memcached memcached -y
apt-get install php-imap -y
phpenmod imap
service apache2 restart

# cloudflare apache2
apt-get install libtool apache2-dev
apt-get install libtool apache2-threaded-dev
wget https://www.cloudflare.com/static/misc/mod_cloudflare/mod_cloudflare.c
apxs2 -a -i -c mod_cloudflare.c
