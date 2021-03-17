#!/bin/bash

exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y
DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc
apt-get -o Acquire::ForceIPv4=true update -y

# Install the dependencies & add Docker to the APT repository
apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

# Update & install Docker-CE
apt update
apt install -y docker-ce

curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Check to ensure Docker is running and installed correctly
systemctl status docker
docker -v

echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
export DEBIAN_FRONTEND=noninteractive 
apt-get upgrade -y


wget https://raw.githubusercontent.com/Peppermint-Lab/Peppermint/master/docker-compose.yml

docker-compose up -d

rm /root/StackScript
rm /root/ssinclude*
echo "Installation complete!"
echo "Installation complete!"
