#!/bin/bash

# <UDF name="ABBERITUSER" Label="Admin Panel Username" example="admin" />
# <UDF name="ABBERITPASSWORD" Label="Admin Panel Password" example="" />

# Logs: tail -f /var/log/stackscript.log
# Logs: cat /var/log/stackscript.log

## REQUIRED IN EVERY MARKETPLACE SUBMISSION
# Add Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y
DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc
apt-get -o Acquire::ForceIPv4=true update -y
## END OF REQUIRED CODE FOR MARKETPLACE SUBMISSION

# TODO: ensure that passwords are not traced before uncommenting following line:
# set -o xtrace

## Remove older installations of Docker:
sudo apt-get remove docker docker-engine docker.io containerd runc

## Install packages to allow apt to use a repository over HTTPS:
sudo apt-get update
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common \
    apache2-utils

lsb_dist="$(. /etc/os-release && echo "$ID")"
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
echo "Installing Docker Engine for $lsb_dist"

## Add Docker’s official GPG key
curl -fsSL "https://download.docker.com/linux/$lsb_dist/gpg" | sudo apt-key add -

## Add docker's stable repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/$lsb_dist \
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

## Configure docker to run as daemon
sudo systemctl enable docker

## Add sudo user
sudo mkdir /etc/abberit/
sudo htpasswd -b -c /etc/abberit/.htpasswd $ABBERITUSER $ABBERITPASSWORD

## common network for all services:
docker network create abnet

docker pull abberit/ab-dev:0.1.8
docker run \
  -d \
  --restart unless-stopped \
  --net abnet \
  -p 8081:8080 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /ab/sites/:/ab/sites \
  -v /etc/abberit/.htpasswd:/etc/abberit/.htpasswd \
  abberit/ab-dev:0.1.8
# `-d ` run detached, i.e. no console output will be shown in main console \
# `--restart unless-stopped ` restart always, unless the customer specifically stopped it \
# `-p 80:8080` map port 80 to container's port 8080 \
# `-v /var/run/docker.sock:/var/run/docker.sock` share `/var/run/docker.sock` to allow connecting to docker from within container \
# `-v /ab/sites/:/ab/sites` share `/ab/sites`` to allow managing websites folder (this folder is shared with app containers) \
# '-v /etc/abberit/.htpasswd:/etc/abberit/.htpasswd' to authenticate users to Admin Panel

vmIP=$(curl -4 https://icanhazip.com)

# wait for appmanager to start
retry=0
while true ;
do
  if [[ "$(curl -s -o /dev/null -w ''%{http_code}'' localhost:8081)" == "200" ]] 
  then
    echo 'localhost:8081 is ready (returned 200)'
    break;
  fi

  ((retry++));
  if [[ $retry -le 10 ]]
  then
    echo "localhost:8081 is not ready (did not return 200), retrying in 2 seconds"
    sleep 2;
  else
    >&2 echo "ERROR: localhost:8081 is not ready (did not return 200)."
    break;
  fi
done

# Create the initial node app:
curl --user "$ABBERITUSER:$ABBERITPASSWORD" --request POST --url http://localhost:8081/api/webapp/app/defaultNodeApp \
     --header 'content-type: application/json' \
     --data '{"appType":"node","hostToAppPortMap":{},"envVars":{},"nginxSettings":[{"listen":"80","serverName":"'$vmIP'","proxyPass":"defaultNodeApp"}]}' \
     --max-time 120

# Start the app:
curl --user "$ABBERITUSER:$ABBERITPASSWORD" --request POST --url http://localhost:8081/api/webapp/start/defaultNodeApp \
     --max-time 60

# cleanup -----------------------------------------------------------------------------------------

## Force IPv4 and noninteractive upgrade after script runs to prevent breaking nf_conntrack for UFW
echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
export DEBIAN_FRONTEND=noninteractive 
apt-get upgrade -y

rm /root/StackScript
rm /root/ssinclude*
echo "Installation complete!"
