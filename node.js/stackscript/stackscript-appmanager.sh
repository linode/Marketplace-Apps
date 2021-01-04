#!/bin/bash

# <UDF name="abuser" Label="Admin Panel Username" example="admin" />
# <UDF name="abpassword" Label="Admin Panel Password" example="" />

# Logs: cat /var/log/stackscript.log

## REQUIRED IN EVERY MARKETPLACE SUBMISSION
# Add Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y
DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc
apt-get -o Acquire::ForceIPv4=true update -y
## END OF REQUIRED CODE FOR MARKETPLACE SUBMISSION

## Remove older installations of Docker:
sudo apt remove docker docker-engine docker.io

## Install packages to allow apt to use a repository over HTTPS:
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    apache2-utils

## Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

## Add docker's stable repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

## install docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
sudo cat >/etc/docker/daemon.json <<EOL
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3" 
  }
}
EOL

## Configure docker client to run without sudo
sudo groupadd docker
sudo usermod -aG docker $USER

## Configure docker to run as daemon
sudo systemctl enable docker

## Add sudo user
sudo mkdir /etc/apache2/
sudo htpasswd -b -c /etc/apache2/.htpasswd $ABUSER $ABPASSWORD

## Prepare folder for SSL certs
sudo mkdir /etc/letsencrypt/

docker pull abberit/ab-dev:0.1.0
docker run \
  -d \
  --restart unless-stopped \
  -p 8081:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /ab/sites/:/ab/sites \
  -v /etc/apache2/.htpasswd:/etc/apache2/.htpasswd \
  abberit/ab-dev:0.1.0
# `-d ` run detached, i.e. no console output will be shown in main console \
# `--restart unless-stopped ` restart always, unless the customer specifically stopped it \
# `-p 80:8080` map port 80 to container's port 8080 \
# `-v /var/run/docker.sock:/var/run/docker.sock` share `/var/run/docker.sock` to allow connecting to docker from within container \
# `-v /ab/sites/:/ab/sites` share `/ab/sites`` to allow managing websites folder (this folder is shared with app containers) \
# '-v /etc/apache2/.htpasswd:/etc/apache2/.htpasswd' to authenticate users to Admin Panel

## Create the initial node app:
curl --user $ABUSER:$ABPASSWORD --request POST --url http://localhost:8081/webapp/app/defaultNodeApp \
     --header 'content-type: application/json' \
     --data '{"appType": "node", "hostToAppPortMap": {"80": "80", "443": "443"}}' \
     --connect-timeout 5 --max-time 10 --retry 30 --retry-delay 2 --retry-connrefused
# --retry 30 --retry-delay 2: retry every 2s up to a 1 minute

# Start the app:
curl --user $ABUSER:$ABPASSWORD --request POST --url http://localhost:8081/webapp/start/defaultNodeApp \
     --connect-timeout 5 --max-time 10 --retry 3 --retry-delay 2 --retry-connrefused
# --retry 3 --retry-delay 2: retry every 2s up to 6s

# cleanup -----------------------------------------------------------------------------------------

## Force IPv4 and noninteractive upgrade after script runs to prevent breaking nf_conntrack for UFW
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
export DEBIAN_FRONTEND=noninteractive 
apt-get upgrade -y

rm /root/StackScript
rm /root/ssinclude*
echo "Installation complete!"
