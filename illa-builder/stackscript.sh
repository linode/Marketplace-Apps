#!/bin/bash
#<UDF name="IBIP" Label="ILLA Builder IP" example="Default: 127.0.0.1" default="127.0.0.1" />
#<UDF name="IBPORT" Label="ILLA Builder Port" example="Default: 80" default="80" />
#<UDF name="IBAPORT" Label="ILLA Builder API Port" example="Default: 9999" default="9999" />
#<UDF name="IBWPORT" Label="ILLA Builder Websocket Port" example="Default: 8000" default="8000" />
#<UDF name="IBPPORT" Label="ILLA Builder PostgreSQL Port" example="Default: 5432" default="5432" />

## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Apt update/upgrade
apt update
apt upgrade

# Install the dependencies & add Docker to the APT repository
apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg2 pwgen ufw
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

# Update & install Docker-CE
apt update
apt install -y docker-ce

# Check to ensure Docker is running and installed correctly
systemctl status docker
docker -v

# Env config
PG_PASS=mysecretpassword
ILLA_HOME_DIR=/var/lib/illa
PG_VOLUMN=${ILLA_HOME_DIR}/database/postgresql
API_SERVER_ADDRESS=$IBIP
API_SERVER_PORT=$IBAPORT
WEBSOCKET_SERVER_ADDRESS=$IBIP
WEBSOCKER_PORT=$IBWPORT
WSS_ENABLED=false
ILLA_DEPLOY_MODE='self-host'


# Init
mkdir -p ${ILLA_HOME_DIR}
mkdir -p ${PG_VOLUMN}
mkdir -p ${ILLA_HOME_DIR}
chmod 0777 ${PG_VOLUMN} # @todo: chmod for MacOS, the gid is "wheel", not "root". and we will fix this later.

# Run
docker run -d \
    --name illa-builder \
    -e POSTGRES_PASSWORD=$PG_PASS \
    -e GIN_MODE=release \
    -e PGDATA=/var/lib/postgresql/data/pgdata \
    -e API_SERVER_ADDRESS=$API_SERVER_ADDRESS \
    -e API_SERVER_PORT=$API_SERVER_PORT \
    -e WEBSOCKET_SERVER_ADDRESS=$WEBSOCKET_SERVER_ADDRESS \
    -e WEBSOCKER_PORT=$WEBSOCKER_PORT \
    -e WSS_ENABLED=$WSS_ENABLED \
    -e ILLA_DEPLOY_MODE=$ILLA_DEPLOY_MODE \
    -v $PG_VOLUMN:/var/lib/postgresql/data \
    -p $IBPPORT:5432 \
    -p $IBPORT:80 \
    -p $WEBSOCKER_PORT:8000 \
    -p $API_SERVER_PORT:9999 \
    illasoft/illa-builder:latest

echo "
********************************************************************************
Welcome to ILLA Builder!
********************************************************************************
  # ILLA Builder:      http://$IP:$BBPORT/
  # Website:           https://www.illacloud.com
  # Documentation:     https://www.illacloud.com/docs/about-illa
  # Github:            https://github.com/illacloud
  # Community Support: https://github.com/orgs/illacloud/discussions
"