#!/usr/bin/env bash
# <UDF name="jwt_enabled" Label="Specifies the enabling the JSON Web Token validation by the ONLYOFFICE Docs. This value set to true by default" example="false" default="true"> 
# <UDF name="jwt_secret" Label="Defines the secret key to validate the JSON Web Token in the request to the ONLYOFFICE Docs. Default JWT value 'secret'. Keep empty if JWT is disabled" example="s4gsd9lfs" default="secret">
# <UDF name="docs_version" Label="Specifies the ONLYOFFICE Docs version. Available version can be checked on https://hub.docker.com/r/onlyoffice/documentserver/tags. Keep empty for install latest version" example="7.2.1" default="latest">

# SSL Settings
# <UDF name="ssl_enabled" Label="Specifies the enabling ssl connection. This value set to false by default" default="false"> 
# <UDF name="lets_encrypt_domain" Label="Domain name for which certificates will be generated." example="example.com" default=""> 
# <UDF name="lets_encrypt_mail" Label="Email address for correct generation of certificates" example="examole@mail.com" default="">

# Enable Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y

# Get and install docker
curl -fsSL get.docker.com | sudo sh

CONTAINER_NAME="onlyoffice-docs"

# Run ONLYOFFICE-Docs without SSL
if [[ "${SSL_ENABLED}" == "false" ]]; then
	sudo docker run -i -t -d -p 80:80 \
		-e JWT_ENABLED=${JWT_ENABLED} \
       		-e JWT_SECRET=${JWT_SECRET} \
		-v /app/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
		-v /app/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
        	-v /app/onlyoffice/DocumentServer/lib:/var/lib/onlyoffice \
        	-v /app/onlyoffice/DocumentServer/rabbitmq:/var/lib/rabbitmq \
        	-v /app/onlyoffice/DocumentServer/redis:/var/lib/redis \
        	-v /app/onlyoffice/DocumentServer/db:/var/lib/postgresql \
		--name ${CONTAINER_NAME} \
		onlyoffice/documentserver:${DOCS_VERSION}
	else 
# Run ONLYOFFICE-Docs with SSL
	sudo docker run -i -t -d -p 80:80 -p 443:443 \
                -e JWT_ENABLED=${JWT_ENABLED} \
                -e JWT_SECRET=${JWT_SECRET} \
                -e LETS_ENCRYPT_DOMAIN=${LETS_ENCRYPT_DOMAIN} \
                -e LETS_ENCRYPT_MAIL=${LETS_ENCRYPT_MAIL} \
                -v /app/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
                -v /app/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
                -v /app/onlyoffice/DocumentServer/lib:/var/lib/onlyoffice \
                -v /app/onlyoffice/DocumentServer/rabbitmq:/var/lib/rabbitmq \
                -v /app/onlyoffice/DocumentServer/redis:/var/lib/redis \
                -v /app/onlyoffice/DocumentServer/db:/var/lib/postgresql \
                --name ${CONTAINER_NAME} \
                onlyoffice/documentserver:${DOCS_VERSION}
fi


# Wait for run
ready_check() {
  echo -e "\e[0;32m Waiting for the launch of DocumentServer... \e[0m"  
  for i in {1..30}; do
    echo "Getting the DocumentServer status: ${i}"
    OUTPUT="$(curl -Is http://localhost/healthcheck/ | head -1 | awk '{ print $2 }')"
    if [ "${OUTPUT}" == "200" ]; then
      echo -e "\e[0;32m DocumentServer is ready \e[0m"
      local DS_READY
      DS_READY='yes'
      break
    else
      sleep 10
    fi
  done
  if [[ "${DS_READY}" != 'yes' ]]; then
    err "\e[0;31m Something goes wrong documentserver does not started, check logs with command --> docker logs -f ${CONTAINER_NAME} \e[0m"
    exit 1
  fi
}

ready_check

# Enable Docs-example by default
sudo docker exec ${CONTAINER_NAME} supervisorctl start ds:example

# Add example to autostart
sudo docker exec ${CONTAINER_NAME} sudo sed 's,autostart=false,autostart=true,' -i /etc/supervisor/conf.d/ds-example.conf

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
