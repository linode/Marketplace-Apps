#!/bin/sh
apk add docker
rc-update add docker boot
service docker start
# Allow Docker daemon to warm up or you get connection error
sleep 10
# Init main Swarm node
if [ "$SWARMINIT" == "y" ] ; then
  docker swarm init --advertise-addr $IP
fi
docker run --restart=unless-stopped --name=openspeedtest -d -p 80:3000 openspeedtest/latest
