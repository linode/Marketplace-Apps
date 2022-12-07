#!/usr/bin/env bash
# <UDF name="jwt_enabled" Label="Specifies the enabling the JSON Web Token validation by the ONLYOFFICE Docs. Defaults to true" example="true or false" default="true"> 
# <UDF name="jwt_secret" Label="Defines the secret key to validate the JSON Web Token in the request to the ONLYOFFICE Docs. Default to secret. Keep empty if jwt is disabled" example="s4gsd9lfs" default="secret">

# Enable Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y

# Get and install docker
curl -fsSL get.docker.com | sudo sh

# Run ONLYOFFICE-Docs with docker
sudo docker run -i -t -d -p 80:80 \
	-e JWT_ENABLED=${JWT_ENABLED} \
        -e JWT_SECRET=${JWT_SECRET} \
	-v /app/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
	-v /app/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
        -v /app/onlyoffice/DocumentServer/lib:/var/lib/onlyoffice \
        -v /app/onlyoffice/DocumentServer/rabbitmq:/var/lib/rabbitmq \
        -v /app/onlyoffice/DocumentServer/redis:/var/lib/redis \
        -v /app/onlyoffice/DocumentServer/db:/var/lib/postgresql \
	--name onlyoffice-docs \
	onlyoffice/documentserver:latest

# Enable Docs-example by default
sudo docker exec onlyoffice-docs supervisorctl start ds:example

# Add MOTD 
cat >/etc/motd <<EOF

Thank you for choose ONLYOFFICE. 

 #######  ##     ## ##   ##      ## #######  ####### ####### ##  #######  #######
##     ## ###    ## ##    ##    ## ##     ## ##      ##         ##     ## ##
##     ## ####   ## ##     ##  ##  ##     ## ##      ##      ## ##        ##
##     ## ## ##  ## ##      ####   ##     ## #####   #####   ## ##        #####
##     ## ##  ##### ##       ##    ##     ## ##      ##      ## ##        ##
##     ## ##    ### ##       ##    ##     ## ##      ##      ## ##     ## ## 
 #######  ##     ## ######## ##     #######  ##      ##      ##  #######  #######

                     #######    #######   #######   #####
                     ##    ##  ##     ## ##     ## ##   ##
                     ##     ## ##     ## ##        ##
                     ##     ## ##     ## ##         #####
                     ##     ## ##     ## ##             ##
                     ##    ##  ##     ## ##     ## ##   ##
                     #######    #######   #######   #####

For more informations about the product features please follow: https://www.onlyoffice.com/compare-editions.aspx

ONLYOFFICE-Docs now is available on localhost:80 or linode_instance_ip:80
EOF
