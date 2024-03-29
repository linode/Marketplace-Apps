#!/usr/bin/env bash
# <UDF name="jwt_enabled" Label="Specifies the enabling the JSON Web Token validation by the ONLYOFFICE Docs. This value set to true by default" example="false" default="true"> 
# <UDF name="jwt_secret" Label="Defines the secret key to validate the JSON Web Token in the request to the ONLYOFFICE Docs. Default random value" example="secret" default="">
# <UDF name="docs_version" Label="Specifies the ONLYOFFICE Docs version. Check available versions on hub.docker onlyoffice/documentserver. Keep empty for install latest" example="7.2.1" default="latest">

# SSL Settings
# <UDF name="ssl_enabled" Label="Specifies the enabling ssl connection. If set to 'true' ssl sercificates will be generate automaticly." default="false"> 
# <UDF name="lets_encrypt_domain" Label="Domain name for which certificates will be generated." example="example.com" default=""> 
# <UDF name="lets_encrypt_mail" Label="Email address for correct generation of certificates" example="mymail@example.com" default="">

# Enable Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y

# Get and install docker
curl -fsSL get.docker.com | sudo sh

CONTAINER_NAME="onlyoffice-docs"

# Run ONLYOFFICE-Docs with SSL
if [[ "${SSL_ENABLED}" == "true" ]]; then
	if [[ -z ${LETS_ENCRYPT_DOMAIN} ]]; then
		echo "Missing required LETS_ENCRYPT_DOMAIN parameter for correct SSL work"
		exit 1
	fi
	if [[ -z ${LETS_ENCRYPT_MAIL} ]]; then
		echo "Missing required LETS_ENCRYPT_MAIL parameter for correct SSL work"
		exit 1
        fi
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
	else 
# Run ONLYOFFICE-Docs without SSL
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

# Enable Docs-example
sudo docker exec ${CONTAINER_NAME} supervisorctl start ds:example

# Add Docs-example to autostart
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
