#!/bin/bash
sudo dpkg --configure -a

# kill any background updater jobs
sudo killall apt apt-get

# helpers
sudo apt-get install dialog apt-utils -y -q

sudo apt-get update -y
sudo apt-get upgrade -y

# firewall
# normal defaults
sudo ufw default deny incoming
sudo ufw default allow outgoing
# ssh on
sudo ufw allow ssh
# dynamic inbound traffic
sudo ufw allow 49152:65535/udp
# TURN
sudo ufw allow 3478/udp
# TURN TCP
sudo ufw allow 80/tcp
# TURNS
sudo ufw allow 443/tcp
# admin (only really should do this for a demo system where it's all on one box)
sudo ufw allow 9090/tcp
sudo ufw allow 9443/tcp
# gateway (only really should do this for a demo system where it's all on one box)
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp

# sip
# sudo ufw allow 5061/udp
# sudo ufw allow 5061/tcp

# we will turn on the firewall at the end because it disconnects us

# install docker
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt-get install -y docker-ce

# entropy fix for docker
sudo apt-get install -y haveged

# install docker compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# retrieve docker compose files
mkdir -p /opt/liveswitch
sudo curl -L "https://raw.githubusercontent.com/jvenema/liveswitch-docker-compose/main/docker-compose-liveswitch.service" -o /opt/liveswitch/docker-compose-liveswitch.service
sudo curl -L "https://raw.githubusercontent.com/jvenema/liveswitch-docker-compose/main/docker-compose.yml" -o /opt/liveswitch/docker-compose.yml

# install liveswitch docker compose
sudo cp /opt/liveswitch/docker-compose-liveswitch.service /etc/systemd/system/
sudo systemctl enable docker
sudo systemctl enable docker-compose-liveswitch
sudo systemctl start docker-compose-liveswitch

# clean up some logs
sudo rm -f /var/log/cloud-init-output.log
sudo rm -f /var/log/dpkg.log
sudo rm -f /var/log/kern.log
sudo rm -f /var/log/ufw.log

# turn on the firewall
sudo ufw --force enable
sudo reboot
