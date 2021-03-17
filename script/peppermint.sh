#!/bin/bash

exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# Update your system
apt update -y

# Upgrade your system
apt upgrade -y

# Install packages over https
apt install apt-transport-https ca-certificates curl software-properties-common -y

# Add the GPG key for the official Docker repository to your system
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add the Docker repo to your APT sources
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

# Update the package database with the new Docker Packages
apt-get update -y

# Install from the Docker repo instead of the default Ubuntu repo
apt-cache policy docker-ce

# Install Docker 
apt install docker-ce -y

# Install Docker-Compose
apt-get install docker-compose -y 

wget https://raw.githubusercontent.com/Peppermint-Lab/Peppermint/master/docker-compose.yml
docker-compose up -d

rm /root/StackScript
rm /root/ssinclude*
echo "Installation complete!"
echo "Installation complete!"
