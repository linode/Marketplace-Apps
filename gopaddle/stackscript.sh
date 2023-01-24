#!/bin/bash
exec >/root/stackscript.log 2>&1
# Install Docker
apt-get update -y
apt-get install -y ca-certificates  curl gnupg  lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
chmod a+r /etc/apt/keyrings/docker.gpg
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install microk8s
apt-get install snapd -y sudo snap install core
export PATH=$PATH:/snap/bin
snap install microk8s --classic --channel=1.25
snap refresh microk8s --channel=1.25
microk8s status --wait-ready


# Install gopaddle
microk8s addons repo add gp-lite https://github.com/gopaddle-io/microk8s-community-addons-gplite.git
microk8s enable gopaddle-lite

echo Waiting for gopaddle services to move to running state ...
microk8s.kubectl wait --for=condition=ready pod -l released-by=gopaddle -n gp-lite --timeout=15m

IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')

echo gopaddle-lite installation is complete ! You can now access the gopaddle dashboard @ http://$IPADDR:30003/
