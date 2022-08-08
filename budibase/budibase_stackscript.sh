#!/bin/bash
#<UDF name="BBPORT" Label="Budibase Port" example="Default: 80" default="80" />

source <ssinclude StackScriptID="401712">
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Set hostname, configure apt and perform update/upgrade
set_hostname
apt_setup_update

# Install the dependencies & add Docker to the APT repository
apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg2 pwgen ufw
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

# Update & install Docker-CE
apt_setup_update
apt install -y docker.io

# Check to ensure Docker is running and installed correctly
systemctl status docker
docker -v

# Install Docker Compose
curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

echo "Creating passwords for /opt/budibase/.env"
VAR_JWT_SECRET=$(pwgen 16)
VAR_MINIO_ACCESS_KEY=$(pwgen 16)
VAR_MINIO_SECRET_KEY=$(pwgen 16)
VAR_COUCH_DB_PASSWORD=$(pwgen 16)
VAR_REDIS_PASSWORD=$(pwgen 16)
VAR_INTERNAL_API_KEY=$(pwgen 16)
IP=`hostname -I | awk '{print$1}'`

mkdir -p /opt/budibase
cd /opt/budibase
echo "Fetch budibase docker compose file"
curl -L https://raw.githubusercontent.com/Budibase/budibase/master/hosting/docker-compose.yaml -o /opt/budibase/docker-compose.yml
echo "Fetch budibase .env template"
curl -L https://raw.githubusercontent.com/Budibase/budibase/master/hosting/.env -o /opt/budibase/.env
echo "Set passwords in /opt/budibase/.env"
sed -i "s/JWT_SECRET=testsecret/JWT_SECRET=$VAR_JWT_SECRET/" /opt/budibase/.env
sed -i "s/MINIO_ACCESS_KEY=budibase/MINIO_ACCESS_KEY=$VAR_MINIO_ACCESS_KEY/" /opt/budibase/.env
sed -i "s/MINIO_SECRET_KEY=budibase/MINIO_SECRET_KEY=$VAR_MINIO_SECRET_KEY/" /opt/budibase/.env
sed -i "s/COUCH_DB_PASSWORD=budibase/COUCH_DB_PASSWORD=$VAR_COUCH_DB_PASSWORD/" /opt/budibase/.env
sed -i "s/REDIS_PASSWORD=budibase/REDIS_PASSWORD=$VAR_REDIS_PASSWORD/" /opt/budibase/.env
sed -i "s/INTERNAL_API_KEY=budibase/INTERNAL_API_KEY=$VAR_INTERNAL_API_KEY/" /opt/budibase/.env
sed -i "s/MAIN_PORT=10000/MAIN_PORT=$BBPORT/" /opt/budibase/.env
docker-compose up -d

cat <<END >/etc/profile.d/budibase_welcome.sh
#!/bin/sh
#
IP=$(hostname -I | awk '{print$1}')
echo "
********************************************************************************
Welcome to Budibase!
To help keep this server secure, the UFW firewall is enabled.
All ports are BLOCKED except 22 (SSH) and the Web UI port $BBPORT.
********************************************************************************
  # Budibase UI:       http://$IP:$BBPORT/
  # Website:           https://budibase.com
  # Documentation:     https://docs.budibase.com
  # Github:            https://github.com/Budibase/budibase
  # Community Support: https://github.com/Budibase/budibase/discussions
  # Restart Budibase:  cd /opt/budibase; docker-compose down; docker-compose up -d
  # Budibase config:   /etc/budibase/.env
"
END
chmod +x /etc/profile.d/budibase_welcome.sh
# Enable UFW and add some rules to it
ufw enable
ufw limit ssh/tcp comment 'Rate limit the SSH port'
ufw allow $BBPORT/tcp comment "TCP Listen port for Budibase"
ufw --force enable

# Cleanup
stackscript_cleanup