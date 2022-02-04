#!/bin/bash

# Add Logging to /var/log/stackscript.log for future troubleshooting
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# apt-get updates
 echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
 export DEBIAN_FRONTEND=noninteractive
 apt-get update -y

# <UDF name="mist_email" label="Mist admin user's email." example="Set your admin user's email."/>

# <UDF name="mist_password" label="Mist admin user's password." example="Set your admin user's password."/>

## install docker
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io

## install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

## get latest mist
mkdir ~/mist && cd ~/mist

export MIST_CE_REPO=https://github.com/mistio/mist-ce/releases/latest
export LATEST_TAG="$(curl -sI "${MIST_CE_REPO}" | grep -Po 'tag\/\K(v\S+)')"

wget https://github.com/mistio/mist-ce/releases/download/$LATEST_TAG/docker-compose.yml

# set CORE_URI
mkdir settings
export IP=$(ip r | grep /24 | grep -Eo "([0-9]{1,3}[\.]){3}[1-9]{1,3}")
echo 'CORE_URI="http://'$IP'"' > settings/settings.py

docker-compose up -d

while !(curl -sSLf http://localhost >/dev/null); do
        sleep 5
done

docker-compose exec -T api ./bin/adduser --admin "${MIST_EMAIL}"  --password "${MIST_PASSWORD}"