#!/bin/bash
# Update the packages on the system from the distribution repositories.	
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install pre-requisites for docker-ce

DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

#Add Docker official GPG key

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
	
#Add repository
	
add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs) stable"

# Download and install utnservice

mkdir /utunnel
	
cd /utunnel 
	
wget https://files.utunnel.io/production/deploy/install_bundle_20.tar
	
tar -xf install_bundle_20.tar

rm -f install_bundle_20.tar
