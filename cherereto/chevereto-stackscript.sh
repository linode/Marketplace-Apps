#!/usr/bin/env bash
# https://github.com/chevereto/linode-marketplace

set -e

CHEVERETO_INSTALLER_TAG="2.2.3"
WORKING_DIR="/var/www/html"

## REQUIRED IN EVERY MARKETPLACE SUBMISSION
# Add Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

## 03-force-ssh-logout.sh
cat >>/etc/ssh/sshd_config <<EOM
Match User root
        ForceCommand echo "Please wait while we get your Chevereto ready..."
EOM

systemctl restart ssh

# 00-update.sh
DEBIAN_FRONTEND=noninteractive apt-get update -qq >/dev/null
apt install -y apache2 libapache2-mod-php
apt install -y mysql-server
apt install -y php
apt install -y php-{common,cli,curl,fileinfo,gd,imagick,intl,json,mbstring,mysql,opcache,pdo,pdo-mysql,xml,xmlrpc,zip}
apt install -y python3-certbot-apache software-properties-common unzip

# 01-fs.sh
cat >/etc/apache2/sites-available/000-default.conf <<EOM
<VirtualHost *:80>
    <Directory /var/www/html>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOM

cat >/etc/update-motd.d/99-one-click <<EOM
#!/usr/bin/env bash

myip=\$(hostname -I | awk '{print\$1}')
cat <<EOF
********************************************************************************
      __                        __     
 ____/ /  ___ _  _____ _______ / /____ 
/ __/ _ \/ -_) |/ / -_) __/ -_) __/ _ \ 
\__/_//_/\__/|___/\__/_/  \__/\__/\___/

Welcome to Linode's One-Click Chevereto server!

To keep this server secure, the UFW firewall is enabled.
All ports are BLOCKED except 22 (SSH), 80 (HTTP), and 443 (HTTPS).

In a web browser, you can view:
 * The Chevereto installer: http://\$myip/installer.php

On the server:
 * The default web root is located at /var/www/html
 * The MySQL root password is saved at
   in /root/.mysql_password
 * Certbot is preinstalled, to configure HTTPS run:
   > certbot --apache -d example.com -d www.example.com

IMPORTANT:
 * After connecting to the server for the first time, immediately install
   Chevereto at http://\$myip/installer.php
 * Secure your database by running:
   > mysql_secure_installation
 * Setup email delivery at http://\$myip/dashboard/settings/email

For help and more information visit https://chevereto.com

********************************************************************************
To delete this message of the day: rm -rf \$(readlink -f \${0})
EOF
EOM
chmod +x /etc/update-motd.d/99-one-click

cat >/etc/cron.d/chevereto <<EOM
* * * * * www-data php /var/www/html/cli.php -C cron
EOM

# 10-php.sh
cat >/etc/php/7.4/apache2/conf.d/chevereto.ini <<EOM
log_errors = On
upload_max_filesize = 50M
post_max_size = 50M
max_execution_time = 30
memory_limit = 512M
EOM

# 11-installer.sh
rm -rf "${WORKING_DIR}"/*
mkdir -p /chevereto && mkdir -p /chevereto/{download,installer}
cd /chevereto/download
curl -S -o installer.tar.gz -L "https://github.com/chevereto/installer/archive/${CHEVERETO_INSTALLER_TAG}.tar.gz"
tar -xvzf installer.tar.gz
mv -v installer-"${CHEVERETO_INSTALLER_TAG}"/installer.php "${WORKING_DIR}"/installer.php
cd $WORKING_DIR

# 12-apache.sh
chown -R www-data: /var/log/apache2
chown -R www-data: /etc/apache2
chown -R www-data: $WORKING_DIR

a2enmod rewrite

# 14-ufw-apache.sh
ufw limit ssh
ufw allow 'Apache Full'
ufw --force enable

# provision.sh
echo $(date -u) ": System provisioning started." >>/var/log/per-instance.log

MYSQL_ROOT_PASS=$(openssl rand -hex 16)
DEBIAN_SYS_MAINT_MYSQL_PASS=$(openssl rand -hex 16)

CHEVERETO_DB_HOST=localhost
CHEVERETO_DB_PORT=3306
CHEVERETO_DB_NAME=chevereto
CHEVERETO_DB_USER=chevereto
CHEVERETO_DB_PASS=$(openssl rand -hex 16)

cat >/root/.mysql_password <<EOM
MYSQL_ROOT_PASS="${MYSQL_ROOT_PASS}"
EOM

mysql -u root -e "CREATE DATABASE $CHEVERETO_DB_NAME;"
mysql -u root -e "CREATE USER '$CHEVERETO_DB_USER'@'$CHEVERETO_DB_HOST' IDENTIFIED BY '$CHEVERETO_DB_PASS';"
mysql -u root -e "GRANT ALL ON *.* TO '$CHEVERETO_DB_USER'@'$CHEVERETO_DB_HOST';"

mysqladmin -u root -h localhost password $MYSQL_ROOT_PASS

mysql -uroot -p${MYSQL_ROOT_PASS} \
    -e "ALTER USER 'debian-sys-maint'@'localhost' IDENTIFIED BY '$DEBIAN_SYS_MAINT_MYSQL_PASS';"

cat >>/etc/apache2/envvars <<EOM
export CHEVERETO_DB_HOST=${CHEVERETO_DB_HOST}
export CHEVERETO_DB_NAME=${CHEVERETO_DB_NAME}
export CHEVERETO_DB_USER=${CHEVERETO_DB_USER}
export CHEVERETO_DB_PASS=${CHEVERETO_DB_PASS}
export CHEVERETO_DB_PORT=${CHEVERETO_DB_PORT}
EOM

systemctl restart apache2

cat >/etc/mysql/debian.cnf <<EOM
# Automatically generated for Debian scripts. DO NOT TOUCH!
[client]
host     = localhost
user     = debian-sys-maint
password = ${DEBIAN_SYS_MAINT_MYSQL_PASS}
socket   = /var/run/mysqld/mysqld.sock
[mysql_upgrade]
host     = localhost
user     = debian-sys-maint
password = ${DEBIAN_SYS_MAINT_MYSQL_PASS}
socket   = /var/run/mysqld/mysqld.sock
EOM

sed -e '/Match User root/d' \
    -e '/.*ForceCommand.*Chevereto.*/d' \
    -i /etc/ssh/sshd_config

systemctl restart ssh

echo $(date -u) ": System provisioning script is complete." >>/var/log/per-instance.log

echo "[OK] Chevereto Installer $CHEVERETO_INSTALLER_TAG provisioned!"
