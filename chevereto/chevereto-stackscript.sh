#!/usr/bin/env bash

set -e

CHEVERETO_INSTALLER_TAG="2.2.3"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
WORKING_DIR="/var/www/html"

## REQUIRED IN EVERY MARKETPLACE SUBMISSION
# Add Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# 00-update.sh
DEBIAN_FRONTEND=noninteractive apt-get update -qq >/dev/null
apt install -y apache2 libapache2-mod-php
apt install -y mysql-server
apt install -y php
apt install -y php-{common,cli,curl,fileinfo,gd,imagick,intl,json,mbstring,mysql,opcache,pdo,pdo-mysql,xml,xmlrpc,zip}
apt install -y python3-certbot-apache software-properties-common unzip

# 01-fs.sh
set -eux
{
    echo "<VirtualHost *:80>"
    echo "    <Directory /var/www/html>"
    echo "        Options Indexes FollowSymLinks"
    echo "        AllowOverride All"
    echo "        Require all granted"
    echo "    </Directory>"
    echo "    ServerAdmin webmaster@localhost"
    echo "    DocumentRoot /var/www/html"
    echo "    ErrorLog \${APACHE_LOG_DIR}/error.log"
    echo "    CustomLog \${APACHE_LOG_DIR}/access.log combined"
    echo "</VirtualHost>"
} >/etc/apache2/sites-available/000-default.conf
set -eux
{
    echo "#!/usr/bin/env bash"
    echo ""
    echo "myip=\$(hostname -I | awk '{print\$1}')"
    echo "cat <<EOF"
    echo "********************************************************************************"
    echo ""
    echo "CHEVERETO"
    echo ""
    echo "Welcome to Linode's One-Click Chevereto server."
    echo ""
    echo "To keep this server secure, the UFW firewall is enabled."
    echo "All ports are BLOCKED except 22 (SSH), 80 (HTTP), and 443 (HTTPS)."
    echo ""
    echo "In a web browser, you can view:"
    echo " * The Chevereto installer: http://\$myip/installer.php"
    echo ""
    echo "On the server:"
    echo " * The default web root is located at /var/www/html"
    echo " * The MySQL root password is saved at"
    echo "   in /root/.mysql_password"
    echo " * Certbot is preinstalled, to configure HTTPS run:"
    echo "   > certbot --apache -d example.com -d www.example.com"
    echo ""
    echo "IMPORTANT:"
    echo " * After connecting to the server for the first time, immediately install"
    echo "   Chevereto at http://\$myip/installer.php"
    echo " * Secure your database by running:"
    echo "   > mysql_secure_installation"
    echo " * Setup email delivery at http://\$myip/dashboard/settings/email"
    echo ""
    echo "For help and more information visit https://chevereto.com"
    echo ""
    echo "********************************************************************************"
    echo "To delete this message of the day: rm -rf \$(readlink -f \${0})"
    echo "EOF"
} >/etc/update-motd.d/99-one-click
set -eux
{
    echo "* * * * * www-data php /var/www/html/cli.php -C cron"
} >/etc/cron.d/chevereto

# 10-php.sh
set -eux
{
    echo "log_errors = On"
    echo "upload_max_filesize = 50M"
    echo "post_max_size = 50M"
    echo "max_execution_time = 30"
    echo "memory_limit = 512M"
} >/etc/php/7.4/apache2/conf.d/chevereto.ini

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

set -eux
{
    echo "export CHEVERETO_DB_HOST=$CHEVERETO_DB_HOST"
    echo "export CHEVERETO_DB_NAME=$CHEVERETO_DB_NAME"
    echo "export CHEVERETO_DB_USER=$CHEVERETO_DB_USER"
    echo "export CHEVERETO_DB_PASS=$CHEVERETO_DB_PASS"
    echo "export CHEVERETO_DB_PORT=$CHEVERETO_DB_PORT"
} >>"/etc/apache2/envvars"

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

echo $(date -u) ": System provisioning script is complete." >>/var/log/per-instance.log

echo "[OK] Chevereto Installer $CHEVERETO_INSTALLER_TAG provisioned!"
