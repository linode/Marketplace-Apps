#!/bin/bash
2	
3	
# Update the packages on the system from the distribution repositories.
4	
apt-get update
5	
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
6	
7	
# Install pre-requisites for docker-ce
8	
DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
9	
10	
#Add Docker official GPG key
11	
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
12	
13	
#Add repository
14	
add-apt-repository  "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs) stable"
15	
16	
# Download and install utnservice
17	
mkdir /utunnel
18	
cd /utunnel 
19	
wget https://files.utunnel.io/production/deploy/install_bundle.tar
20	
tar -xf install_bundle.tar
21	
rm -f install_bundle.tar
