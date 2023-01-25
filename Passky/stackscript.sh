#!/bin/bash

# <UDF name="website" Label="Website" example="passky.domain.com" />
# <UDF name="email" Label="Email Address" example="info@rabbit-company.com" />
# <UDF name="adminuser" Label="Admin Username" />
# <UDF name="admin_password" Label="Admin Password" />

# Motd
cat << EOF > /etc/motd

  _____              _          
 |  __ \            | |         
 | |__) |_ _ ___ ___| | ___   _ 
 |  ___/ _\` / __/ __| |/ / | | |
 | |  | (_| \__ \__ \   <| |_| |
 |_|   \__,_|___/___/_|\_\\__,  |
                           __/ |
                          |___/ 

Installing...
Please logout and come back in few minutes.

EOF

## REQUIRED IN EVERY MARKETPLACE SUBMISSION
# Add Logging to /var/log/stackscript.log for future troubleshooting
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y
DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc
apt-get -o Acquire::ForceIPv4=true update -y
## END OF REQUIRED CODE FOR MARKETPLACE SUBMISSION

## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

# Install docker compose
system_install_package docker-compose

#
# Passky Server
#
wget https://github.com/Rabbit-Company/Passky-Server/releases/latest/download/passky-server.tar.xz
tar -xf passky-server.tar.xz
cd passky-server
cp .env.example .env

SERVER_CORES=$(grep -c ^processor /proc/cpuinfo)
IP_ADDRESS=$(system_primary_ip)

sed -i "s/SERVER_CORES=1/SERVER_CORES=$SERVER_CORES/g" .env
sed -i "s/ADMIN_USERNAME=admin/ADMIN_USERNAME=$ADMINUSER/g" .env
sed -i "s/ADMIN_PASSWORD=/ADMIN_PASSWORD=$ADMIN_PASSWORD/g" .env

docker-compose up -d

apache_install
a2enmod proxy && a2enmod proxy_http && systemctl restart apache2
echo "<VirtualHost *:80>" > /etc/apache2/sites-available/$WEBSITE.conf
echo "  ProxyPreserveHost On" >> /etc/apache2/sites-available/$WEBSITE.conf
echo "  ProxyRequests Off" >> /etc/apache2/sites-available/$WEBSITE.conf
echo "  ServerName $WEBSITE" >> /etc/apache2/sites-available/$WEBSITE.conf
echo "  ProxyPass / http://localhost:8080/" >> /etc/apache2/sites-available/$WEBSITE.conf
echo "  ProxyPassReverse / http://localhost:8080/" >> /etc/apache2/sites-available/$WEBSITE.conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/$WEBSITE.conf
a2ensite "$WEBSITE"
systemctl restart apache2

# Install SSL
system_install_package python3-certbot-apache
cat << EOF > /usr/local/bin/installCert
#!/bin/bash

if ! certbot -n --apache --agree-tos --redirect -d $WEBSITE -m $EMAIL; then
  echo "There was a problem while installing SSL certificate. Make sure your A record for domain: $WEBSITE does redirect to IP: $IP_ADDRESS"
else
  echo "Certificate installed successfully."
fi
EOF
chmod +x /usr/local/bin/installCert

# Configure auto-renewal for the certificate
crontab -l > cron
echo "0 4 * * * /usr/bin/certbot renew" >> cron
crontab cron
rm cron

stackscript_cleanup

# Motd
cat << EOF > /etc/motd

  _____              _          
 |  __ \            | |         
 | |__) |_ _ ___ ___| | ___   _ 
 |  ___/ _\` / __/ __| |/ / | | |
 | |  | (_| \__ \__ \   <| |_| |
 |_|   \__,_|___/___/_|\_\\__,  |
                           __/ |
                          |___/ 

Admin Panel:
  Link: http://$IP_ADDRESS (https://$WEBSITE)
  Username: $ADMINUSER
  Password: $ADMIN_PASSWORD

To install SSL certificate please run command: installCert

EOF