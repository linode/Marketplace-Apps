#!/bin/bash
# Install Kepler
# <UDF name="site_title" Label="Site Title" default="My Kepler Site" example="My Blog" />
# <UDF name="wpadmin" Label="Wordpress Admin Username" example="Username for your WordPress admin panel" />
# <UDF name="wp_password" Label="Wordpress Admin Password" example="an0th3r_s3cure_p4ssw0rd" />
# <UDF name="email" Label="Wordpress Admin Email Address" example="Your email address" />
# <UDF name="pubkey" Label="Your SSH public key" default="" />

# Set hostname, configure apt and perform update/upgrade
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1
set_hostname
apt_setup_update
if [[ "$PUBKEY" != "" ]]; then
  add_pubkey
fi
apt install haveged -y
DBROOT_PASSWORD=`head -c 32 /dev/random | base64`
DB_PASSWORD=`head -c 32 /dev/random | base64 | tr -d /=+`
# UFW update
ufw_install
ufw allow http
ufw allow https
ufw allow 25
ufw allow 587
ufw allow 110
ufw enable
fail2ban_install
# Set MySQL root password on install
mysql_root_preinstall
run_mysql_secure_installation
### Installations
# Install PHP
apt-get install php7.0 php7.0-cli php7.0-curl php7.0-mysql \
php7.0-mcrypt php-pear libapache2-mod-php7.0 php7.0-gd php7.0-common \
php7.0-xml php7.0-zip apache2 mysql-server unzip sendmail -y
#Install WP
wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
chmod 755 /usr/local/bin/wp
### Configurations
# MySQL
mysql -uroot -p"$DBROOT_PASSWORD" -e "CREATE DATABASE wordpressdb"
mysql -uroot -p"$DBROOT_PASSWORD" -e "GRANT ALL ON wordpressdb.* TO 'wordpress'@'localhost' IDENTIFIED BY '$DB_PASSWORD'";
mysql -uroot -p"$DBROOT_PASSWORD" -e "FLUSH PRIVILEGES";
# Apache
rm /var/www/html/index.html
mkdir /var/www/wordpress
# Configuration of virtualhost file, disables xmlrpc
cat <<END > /etc/apache2/sites-available/wordpress.conf
<Directory /var/www/wordpress/>
    Require all granted
</Directory>
<VirtualHost *:80>
    ServerName $IP
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/wordpress/
    ErrorLog /var/log/apache2/wordpress/error.log
    CustomLog /var/log/apache2/wordpress/access.log combined
    <files xmlrpc.php>
      order allow,deny
      deny from all
    </files>
</VirtualHost>
END
mkdir -p /var/log/apache2/wordpress
touch /var/log/apache2/wordpress/error.log
touch /var/log/apache2/wordpress/access.log
# Enable Keepalives
sed -ie "s/KeepAlive Off/KeepAlive On/g" /etc/apache2/apache2.conf
# Configure Wordpress site
cd /var/www/wordpress
wp core download --allow-root
wp core config --allow-root \
--dbhost=localhost \
--dbname=wordpressdb \
--dbuser=wordpress \
--dbpass="$DB_PASSWORD"
wp core install --allow-root \
--url="$IP" \
--title="$SITE_TITLE" \
--admin_user="$WPADMIN" \
--admin_email="$EMAIL" \
--admin_password="$WP_PASSWORD" \
--path="/var/www/wordpress/"
#Cron for WP updates
echo "* 1 * * * '/usr/local/bin/wp core update --allow-root --path=/var/www/wordpress' > /dev/null 2>&1" >> wpcron
crontab wpcron
rm wpcron
# Disable the default virtual host to minimize security risks:
a2dissite 000-default.conf
a2ensite wordpress.conf
# Install Kepler theme
wget https://storage.googleapis.com/kepler-download/kepler-theme.zip?ignoreCache=1 -O kepler-theme.zip
wp theme install --allow-root kepler-theme.zip --activate
# Install Kepler builder plugin
wget https://storage.googleapis.com/kepler-download/kepler-builder.zip -O kepler-builder.zip
wp plugin install --allow-root kepler-builder.zip --activate
#wp plugin install --allow-root woocommerce
#wp plugin activate --allow-root woocommerce
chown www-data:www-data -R /var/www/wordpress/
# Restart services
systemctl restart mysql
systemctl restart apache2
stackscript_cleanup