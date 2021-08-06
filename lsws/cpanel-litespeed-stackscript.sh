#!/bin/bash
## Install cPanel
yum install -y kernel grub2
sed -i -e "s/GRUB_TIMEOUT=5/GRUB_TIMEOUT=10/" /etc/default/grub
sed -i -e "s/crashkernel=auto rhgb console=ttyS0,19200n8/console=ttyS0,19200n8/" /etc/default/grub
mkdir /boot/grub
grub2-mkconfig -o /boot/grub/grub.cfg
systemctl stop firewalld.service
systemctl disable firewalld.service
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl enable network
systemctl start network
yum remove NetworkManager -y
cd /home 
curl -o latest -L https://securedownloads.cpanel.net/latest  && sh latest
yum remove ea-apache24-mod_ruid2 -y
## Install LSWS on cPanel
ADMIN_PASS=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16 ; echo '')
cat <<EOT >>/home/lsws.options
## 1 = enable, 0 = disable, 2 = user home directory
php_suexec="2"
port_offset="0"
admin_user="admin"
admin_pass="${ADMIN_PASS}"
admin_email="root@localhost"
easyapache_integration="1"
auto_switch_to_lsws="1"
deploy_lscwp="1"
EOT
bash <( curl https://get.litespeed.sh ) TRIAL