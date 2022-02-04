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
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y
DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc
apt-get -o Acquire::ForceIPv4=true update -y
## END OF REQUIRED CODE FOR MARKETPLACE SUBMISSION

#### Here are Linodes Marketplace Helpers. You can source them as shown below and use any functions in those scripts 
## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

# If your application needs cPanel, you can source our existing cPanel Marketplace APP:
source <ssinclude StackScriptID=595742> # cPanel Marketplace App 

# If your application needs Wordpress, you can source our existing Wordpress Marketplace APP:
source <ssinclude StackScriptID=401697> # Wordpress Marketplace App 

# Here is an example of how to change a setting in a specific file using sed
sed -ie "s/KeepAlive Off/KeepAlive On/g" /etc/apache2/apache2.conf

# Here is how to create a configuration file
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

# Here is a way to handle installations that require interaction using expect
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

# Here is how to run MySQL commands via commandline
mysql -uroot -p$DB_PASSWORD -e "CREATE DATABASE wordpress;"
mysql -uroot -p$DB_PASSWORD -e "CREATE USER '$DBUSER' IDENTIFIED BY '$DBUSER_PASSWORD';"
mysql -uroot -p$DB_PASSWORD -e "GRANT ALL PRIVILEGES ON wordpress.* TO '$DBUSER';"

# Here is how to install multiple packages at one time
apt-get install -y php php-pear libapache2-mod-php php-mysql php-gd
  
# Stackscript cleanup
rm /root/StackScript
rm /root/ssinclude*
echo "Installation complete!"