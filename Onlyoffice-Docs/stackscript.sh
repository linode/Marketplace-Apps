#!/usr/bin/env bash
# <UDF name="jwt_enabled" Label="Specifies the enabling the JSON Web Token validation by the ONLYOFFICE Docs. Defaults to true" example="true or false" default="true"> 
# <UDF name="jwt_secret" Label="Defines the secret key to validate the JSON Web Token in the request to the ONLYOFFICE Docs." example="s4gsd9lfs" default="secret">
# <UDF name="docs_version" Label="Defines version of Onlyoffice-Docs that you want to run. latest by default" example="7.2.0" default="latest">

# Enable Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y

# Get and install docker
curl -fsSL get.docker.com | sudo sh

# Run Onlyoffice-Docs with docker
sudo docker run -i -t -d -p 80:80 \
	-e JWT_ENABLED=${JWT_ENABLED} \
        -e JWT_SECRET=${JWT_SECRET} \
	-v /app/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
	-v /app/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
        -v /app/onlyoffice/DocumentServer/lib:/var/lib/onlyoffice \
        -v /app/onlyoffice/DocumentServer/rabbitmq:/var/lib/rabbitmq \
        -v /app/onlyoffice/DocumentServer/redis:/var/lib/redis \
        -v /app/onlyoffice/DocumentServer/db:/var/lib/postgresql \
	onlyoffice/documentserver:${DOCS_VERSION}

# Add MOTD 
cat >/etc/motd <<EOF

Thank you for install

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
EOF
