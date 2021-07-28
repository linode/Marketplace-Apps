#!/bin/bash
#<UDF name="YEMAIL" Label="Yacht Email" example="admin@yacht.local" default="admin@yacht.local" />
#<UDF name="YPASSWORD" Label="Yacht Password" example="Password" />
#<UDF name="COMPOSE_SUPPORT" Label="Yacht Compose Support" example="Yes" default="Yes" oneof="Yes,No" />
#<UDF name="YACHT_THEME" Label="Yacht Theme" example="Default" default="Default" oneof="Default,RED,OMV" />


source <ssinclude StackScriptID="401712">
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Set hostname, configure apt and perform update/upgrade
set_hostname
apt_setup_update

# Install the dependencies & add Docker to the APT repository
apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg2
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

# Update & install Docker-CE
apt_setup_update
apt install -y docker-ce

# Check to ensure Docker is running and installed correctly
systemctl status docker
docker -v

# Install Docker Compose
curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

echo "Testing Variables"
echo $COMPOSE_SUPPORT
echo $YEMAIL

if [ "$COMPOSE_SUPPORT" == "Yes" ]; then
    mkdir -p /opt/Yacht/compose/example
    docker volume create yacht_data
    docker run -d \
        --name=yacht \
        -p 8000:8000 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v yacht_data:/config \
        -v /opt/Yacht/compose:/compose \
        -e COMPOSE_DIR=/compose/ \
        -e THEME=$YACHT_THEME \
        -e ADMIN_EMAIL=$YEMAIL \
        -e ADMIN_PASSWORD=$YPASSWORD \
        selfhostedpro/yacht:latest
    printf "\nThe default compose directory is /opt/Yacht/compose.\nAn example project has been added there." > /etc/update-motd.d/99-yacht
    curl -L https://raw.githubusercontent.com/SelfhostedPro/selfhosted_templates/yacht/Template/Compose/example/docker-compose.yml -o /opt/Yacht/compose/example/docker-compose.yml
elif [ "$COMPOSE_SUPPORT" == "No" ]; then
    docker volume create yacht
    docker run -d \
        --name=yacht \
        -p 8000:8000 \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v yacht_data:/config \
        -e THEME=$YACHT_THEME \
        -e ADMIN_EMAIL=$YEMAIL \
        -e ADMIN_PASSWORD=$YPASSWORD \
        selfhostedpro/yacht:latest
    
fi

# Cleanup
stackscript_cleanup