#!/bin/bash

# <UDF name="ssuser" Label="New user" example="username" />
# <UDF name="sspassword" Label="New user password" example="Password" />
# <UDF name="hostname" Label="Hostname" example="examplehost" />
# <UDF name="website" Label="Website" example="example.com" />
# <UDF name="db_password" Label="MySQL root Password" />
# <UDF name="dbuser" Label="MySQL Username" />
# <UDF name="dbuser_password" Label="MySQL User Password" />

## REQUIRED IN EVERY MARKETPLACE SUBMISSION
# Add Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y
DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc
apt-get -o Acquire::ForceIPv4=true update -y
## END OF REQUIRED CODE FOR MARKETPLACE SUBMISSION

# Add sudo user
adduser $SSUSER --disabled-password --gecos "" && \
echo "$SSUSER:$SSPASSWORD" | chpasswd
adduser $SSUSER sudo

# Set hostname
IP=`hostname -I | awk '{print$1}'`
HOSTNAME=`dnsdomainname -A`
hostnamectl set-hostname $HOSTNAME
echo $IP $HOSTNAME  >> /etc/hosts

# Install and configure Fail2ban
apt-get install fail2ban -y
cd /etc/fail2ban
cp fail2ban.conf fail2ban.local
cp jail.conf jail.local
systemctl start fail2ban
systemctl enable fail2ban

# Install apache
apt-get install -y apache2

# Edit apache config
sed -ie "s/KeepAlive Off/KeepAlive On/g" /etc/apache2/apache2.conf

# Create a copy of the default Apache configuration file for your site
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/$WEBSITE.conf

# Configuration of vhost file
cat <<END >/etc/apache2/sites-available/$WEBSITE.conf
<Directory /var/www/html/$WEBSITE/public_html>
    Require all granted
</Directory>
<VirtualHost *:80>
    ServerName $WEBSITE
    ServerAlias www.$WEBSITE
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/$WEBSITE/public_html
    ErrorLog /var/www/html/$WEBSITE/logs/error.log
    CustomLog /var/www/html/$WEBSITE/logs/access.log combined
</VirtualHost>
END

# Make public_html & logs
mkdir -p /var/www/html/$WEBSITE/{public_html,logs}

# Remove default apache page
rm /var/www/html/index.html

# Install wordpress
cd /var/www/html/$WEBSITE/public_html
wget -O /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
tar -xzf /tmp/wordpress.tar.gz --strip-components=1
chown -R www-data:www-data /var/www/html/$WEBSITE/

# Eemove tar file
rm /tmp/wordpress.tar.gz

# Link your virtual host file from the sites-available directory to the sites-enabled directory
a2ensite $WEBSITE.conf

# Disable the default virtual host to minimize security risks
a2dissite 000-default.conf

# Restart apache
systemctl restart apache2

# Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
echo "mysql-server mysql-server/root_password password $DB_PASSWORD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DB_PASSWORD" | debconf-set-selections
apt-get install -y mysql-server

# Installs expect, runs mysql_secure_installation and runs mysql secure installation.
apt-get install -y expect
SECURE_MYSQL=$(expect -c "
set timeout 10
spawn mysql_secure_installation
expect \"Enter current password for root (enter for ):\"
send \"$DB_PASSWORD\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "$SECURE_MYSQL"
# Add Wordpress user & database
mysql -uroot -p$DB_PASSWORD -e "CREATE DATABASE wordpress;"
mysql -uroot -p$DB_PASSWORD -e "CREATE USER '$DBUSER' IDENTIFIED BY '$DBUSER_PASSWORD';"
mysql -uroot -p$DB_PASSWORD -e "GRANT ALL PRIVILEGES ON wordpress.* TO '$DBUSER';"

# Restart MySQL
systemctl restart mysql

# Installing PHP
apt-get install -y php php-pear libapache2-mod-php php-mysql php-gd

# Making directory for php | Giving apache permissions | Restarting PHP
mkdir /var/log/php
chown www-data /var/log/php
systemctl restart apache2
  
# Force IPv4 and noninteractive upgrade after script runs to prevent breaking nf_conntrack for UFW
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
export DEBIAN_FRONTEND=noninteractive 
apt-get upgrade -y

rm /root/StackScript
rm /root/ssinclude*
echo "Installation complete!"

