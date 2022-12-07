#!/usr/bin/env bash

#Onlyoffice-docs StackScript UDF variables


# Enable Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y

#Get docker
curl -fsSL get.docker.com | sudo sh

# Run Onlyoffice Docker-DocumentServer
sudo docker run -i -t -d -p 80:80 \
	-e JWT_ENABLED=${JWT_STATUS} \
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

Thank you for choosing! 
For help and documentation visit: https://helpcenter.onlyoffice.com/installation/docs-index.aspx
EOF
