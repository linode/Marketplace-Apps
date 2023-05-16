#!/bin/bash
### linode
## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# install docker
curl -fsSL https://get.docker.com -o get-docker.sh
bash ./get-docker.sh

# install haveged
sudo apt-get install -y haveged

# Install Appwrite
docker run --rm \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume "$(pwd)"/appwrite:/usr/src/code/appwrite:rw \
    appwrite/appwrite:1.3 sh -c "install --httpPort=80 --httpsPort=443 --interactive=N"
