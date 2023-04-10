#!/usr/bin/bash

## REQUIRED IN EVERY MARKETPLACE SUBMISSION
# Add Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1
# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y
## END OF REQUIRED CODE FOR MARKETPLACE SUBMISSION

# Install docker
curl -fsSL https://get.docker.com | sudo sh

# Adjust permissions
sudo mkdir -p /mnt/ncdata
sudo chown -R 33:0 /mnt/ncdata

# Install Nextcloud
sudo docker run -d \
--name nextcloud-aio-mastercontainer \
--restart always \
-p 80:80 \
-p 8080:8080 \
-p 8443:8443 \
-e NEXTCLOUD_MOUNT=/mnt/ \
-e NEXTCLOUD_DATADIR=/mnt/ncdata \
--volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
--volume /var/run/docker.sock:/var/run/docker.sock:ro \
nextcloud/all-in-one:latest

# Some Info
cat << EOF > /etc/motd

 #    #  ######  #    #   #####   ####   #        ####   #    #  #####
 ##   #  #        #  #      #    #    #  #       #    #  #    #  #    #
 # #  #  #####     ##       #    #       #       #    #  #    #  #    #
 #  # #  #         ##       #    #       #       #    #  #    #  #    #
 #   ##  #        #  #      #    #    #  #       #    #  #    #  #    #
 #    #  ######  #    #     #     ####   ######   ####    ####   #####

If you point a domain to this server ($(hostname -I | cut -f1 -d' ')), you can open the admin interface at https://yourdomain.com:8443
Otherwise you can open the admin interface at https://$(hostname -I | cut -f1 -d' '):8080
    
Further documentation is available here: https://github.com/nextcloud/all-in-one

EOF

# Install unattended upgrades
sudo apt-get install unattended-upgrades -y
