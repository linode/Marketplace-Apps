#!/bin/bash

# <UDF name="url" label="The domain/subdomain for SeaTable Server" example="https://seatable.example.org" />
# <UDF name="le" label="Get a Let's Encrypt certificate" default="True" oneOf="True,False" />
# <UDF name="timezone" label="Choose your timezone (e.g Europe/Berlin)" example="Choices can be found here: http://en.wikipedia.org/wiki/List_of_tz_zones_by_name" default="Etc/UTC" />

source <ssinclude StackScriptID="1">

## REQUIRED IN EVERY MARKETPLACE SUBMISSION
# Add Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1
# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y
## END OF REQUIRED CODE FOR MARKETPLACE SUBMISSION

# Update and basic installs
system_update
debian_upgrade
enable_fail2ban
system_install_package ufw ca-certificates curl gnupg lsb-release curl pwgen

# Install docker
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
chmod a+r /etc/apt/keyrings/docker.gpg
apt-get -y update
apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-compose

# Pull current seatable container
docker pull seatable/seatable-enterprise:latest
mkdir /opt/seatable
wget -O "/opt/seatable/docker-compose.yml" "https://manual.seatable.io/docker/Enterprise-Edition/docker-compose.yml"

# Prepare SeaTable
MYSQL_PASSWORD=`pwgen -s 30 1`
sed -i "s|DB_ROOT_PASSWD=.*|DB_ROOT_PASSWD=${MYSQL_PASSWORD}|" /opt/seatable/docker-compose.yml
sed -i "s|MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=${MYSQL_PASSWORD}|" /opt/seatable/docker-compose.yml
sed -i "s|SEATABLE_SERVER_LETSENCRYPT=.*|SEATABLE_SERVER_LETSENCRYPT=${LE}|" /opt/seatable/docker-compose.yml
sed -i "s|SEATABLE_SERVER_HOSTNAME=.*|SEATABLE_SERVER_HOSTNAME=${URL}|" /opt/seatable/docker-compose.yml
sed -i "s|TIME_ZONE=.*|TIME_ZONE=${TIMEZONE}|" /opt/seatable/docker-compose.yml

# Add a license
mkdir -p /opt/seatable/seatable-data/seatable
touch /opt/seatable/seatable-data/seatable/seatable-license.txt
cat << EOF > /opt/seatable/seatable-data/seatable/seatable-license.txt
#SeaTable server licence
Name = "Cloud Trial"
Licencetype = "User"
LicenceKEY = "1672935702"
ProductID = "SeaTable server"
Expiration = "2024-01-31"
MaxUsers = "3"
Mode = "subscription"
Hash = "045af708265d7d549cad51fc2b678272a1d15ab8cbfbf05734e371504bb72b388f4441493c7bfeccce7c19ac9c6877cb8f3aecc3beebe685db007832e1c0231728a92772d45dc1c08facbc225d90776f86d34cb4154bafe7c983b6767ffb31a74b133de61edf15c170564fcefb6e457012f63b95ed4aaf6fd2e1e1cfc2ad93a682cfab2fe86f427f7d93ae9b69cbaf02a7565074a95a8c1176402f250d2e815ab206a6b65009c65d94259772ab31a00c11e5c6b57fda0fbb1b22a69734c10214594a5d7b4c88a995eaeb3a65f9aa5d163d9e5c09f73105a4ef760a8421fb66d1982da739c42808fded9a95e456090747e494b0a1aee2a40f388d9f1146051754"
EOF

# firewall
ufw limit ssh
ufw allow 80
ufw allow 443
ufw --force enable

# Message of the day
cat << EOF > /etc/motd
#############################
#############################
SeaTable Enterprise Server

To finish the installation, change to the directory /opt/seatable and follow our deployment instructions at https://manual.seatable.io/docker/Enterprise-Edition/Deploy%20SeaTable-EE%20with%20Docker/.
You can skip the beginning and start directly with the adjustment of the docker-compose.yml file.

Please visit https://forum.seatable.io for SeaTable community support.
#############################
#############################

EOF

echo "Installation complete"
all_set
stackscript_cleanup
