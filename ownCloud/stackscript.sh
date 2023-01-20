#!/usr/bin/env bash
### ownCloud OCA w/ optional SSH Security, DNS records, and Certbot SSL
### This update automates the installer GUI that the user previously had
### to complete on their own.
### UDF Variables for the StackScript
## ownCloud Settings
#<UDF name="oc_admin" label="The name of the admin user for ownCloud">
#<UDF name="oc_admin_password" label="The password for ownCloud's admin user">
#<UDF name="soa_email_address" label="Admin Email for the ownCloud server" >
## LAMP Stack Settings
#<UDF name="db_name" label="The name of the database" default="owncloud">
#<UDF name="db_root_password" label="The root password for the database">
#<UDF name="db_username" label="The name of the database user to create" default="owncloud">
#<UDF name="db_user_password" label="The password for the created database user">
## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" default="">
#<UDF name="pubkey" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">
## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is required for creating DNS records." default="">
#<UDF name="subdomain" label="The subdomain for the Linode's DNS record (Requires API token)" default="">
#<UDF name="domain" label="The domain for the Linode's DNS record (Requires API token)" default="">
### Logging and other debugging helpers
# Enable logging for the StackScript
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1
# Source the Bash StackScript Library and the API functions for DNS
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>
# Source and run the New Linode Setup script for DNS/SSH configuration
# This also sets some useful variables, like $IP and $FQDN
source <ssinclude StackScriptID=666912>
## Update
apt_setup_update
## Local Functions used by this StackScript
function owncloud_install {
    system_install_package unzip php-gd php-json php-curl php-mbstring  \
                                 php-intl php-imagick php-xml php-zip
    cd /var/www
    wget https://download.owncloud.com/server/stable/owncloud-complete-latest.zip
    unzip owncloud-complete-latest.zip
    chown -R www-data:www-data owncloud
    rm owncloud-complete-latest.zip
        local -a input_text=(
            "Alias / \"/var/www/owncloud/\""
            "<Directory /var/www/owncloud/>"
            "  Options +FollowSymlinks"
            "  AllowOverride All"
            "<IfModule mod_dav.c>"
            "  Dav off"
            "</IfModule>"
            "SetEnv HOME /var/www/owncloud"
            "SetEnv HTTP_HOME /var/www/owncloud"
            "</Directory>"
        )
    for i in "${input_text[@]}"; do
        echo "$i" >> /etc/apache2/sites-available/owncloud.conf
    done
    a2ensite owncloud
    a2enmod rewrite headers env dir mime
    sed -i '/^memory_limit =/s/=.*/= 512M/' /etc/php/7.4/apache2/php.ini
    systemctl restart apache2
    echo "ownCloud is installed"
}
function owncloud_vhost_configure {
    local -r fqdn="$1"
    local -r soa_email_address="$2"
    local -a input_text=(
        "<VirtualHost *:80>"
        "  ServerName ${fqdn}"
        "  ServerAdmin ${soa_email_address}"
        "  DocumentRoot /var/www/owncloud"
        "  <directory /var/www/owncloud>"
        "    Require all granted"
        "    AllowOverride All"
        "    Options FollowSymLinks MultiViews"
        "    SetEnv HOME /var/www/owncloud"
        "    SetEnv HTTP_HOME /var/www/owncloud"
        "  </directory>"
        "</VirtualHost>"
    )
    echo "" >> /etc/apache2/sites-available/owncloud.conf
    for i in "${input_text[@]}"; do
        echo "$i" >> /etc/apache2/sites-available/owncloud.conf
    done
}
## Main Script
# Install and configure the LAMP Stack
lamp_stack "$DB_NAME" "$DB_ROOT_PASSWORD" "${DB_USERNAME:-owncloud}" "$DB_USER_PASSWORD"
# Install ownCloud to be accessed via domain and configure the VirtualHost
owncloud_install "$FQDN"
owncloud_vhost_configure "$FQDN" "$SOA_EMAIL_ADDRESS"
# Configure ownCloud - This replaces the installer GUI that was in the previous version of this OCA
sudo -u www-data php /var/www/owncloud/occ maintenance:install \
                                            --database "mysql" \
                                            --database-name "$DB_NAME" \
                                            --database-user "${DB_USERNAME:-owncloud}" \
                                            --database-pass "$DB_USER_PASSWORD" \
                                            --admin-user "$OC_ADMIN" \
                                            --admin-pass "$OC_ADMIN_PASSWORD"
sudo -u www-data php /var/www/owncloud/occ conf:sys:set trusted_domains 1 --value=$FQDN
sudo -u www-data php /var/www/owncloud/occ conf:sys:set trusted_domains 2 --value=$IP
echo "Trusted Domain setting added"
# Open the needed firewall ports
ufw allow http
ufw allow https
apt install certbot python3-certbot-apache -y
certbot_ssl "$FQDN" "$SOA_EMAIL_ADDRESS" 'apache'
# Clean up
stackscript_cleanup
