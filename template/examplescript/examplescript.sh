#!/bin/bash
##
# <UDF name="ssuser" Label="New user" example="username" />
# <UDF name="sspassword" Label="New user password" example="Password" />
# <UDF name="hostname" Label="Hostname" example="examplehost" />
# <UDF name="website" Label="Website" example="example.com" />
# <UDF name="db_password" Label="MySQL root Password" />
# <UDF name="dbuser" Label="MySQL Username" />
# <UDF name="dbuser_password" Label="MySQL User Password" />

# add sudo user
adduser $SSUSER --disabled-password --gecos "" && \
echo "$SSUSER:$SSPASSWORD" | chpasswd
adduser $SSUSER sudo


# updates
apt-get -o Acquire::ForceIPv4=true update -y
DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc
apt-get -o Acquire::ForceIPv4=true update -y

# set hostname
hostnamectl set-hostname $HOSTNAME
echo "127.0.0.1   $HOSTNAME" >> /etc/hosts

# install apache
apt-get install -y apache2

# edit apache config
sed -ie "s/KeepAlive Off/KeepAlive On/g" /etc/apache2/apache2.conf


# create a copy of the default Apache configuration file for your site
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/$WEBSITE.conf

# configuration of vhost file
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

# make public_html & logs
mkdir -p /var/www/html/$WEBSITE/{public_html,logs}

# remove default apache page
rm /var/www/html/index.html

# install wordpress
cd /var/www/html/$WEBSITE/public_html
wget -O /tmp/wordpress.tar.gz https://wordpress.org/latest.tar.gz
tar -xzf /tmp/wordpress.tar.gz --strip-components=1
chown -R www-data:www-data /var/www/html/$WEBSITE/
# remove tar file
rm /tmp/wordpress.tar.gz


# link your virtual host file from the sites-available directory to the sites-enabled directory
a2ensite $WEBSITE.conf


# disable the default virtual host to minimize security risks
a2dissite 000-default.conf


# restart apache
systemctl restart apache2


# install MySQL Server in a Non-Interactive mode. Default root password will be "root"
echo "mysql-server mysql-server/root_password password $DB_PASSWORD" | debconf-set-selections
echo "mysql-server mysql-server/root_password_again password $DB_PASSWORD" | debconf-set-selections
apt-get install -y mysql-server

mysql -uroot -p$DB_PASSWORD -e "CREATE DATABASE wordpress;"
mysql -uroot -p$DB_PASSWORD -e "CREATE USER '$DBUSER' IDENTIFIED BY '$DBUSER_PASSWORD';"
mysql -uroot -p$DB_PASSWORD -e "GRANT ALL PRIVILEGES ON wordpress.* TO '$DBUSER';"

systemctl restart mysql

# installing php
apt-get install -y php7.0 php-pear libapache2-mod-php7.0 php7.0-mysql php-gd

# making directory for php? giving apache permissions to that log? restarting php
mkdir /var/log/php
chown www-data /var/log/php
systemctl restart apache2
