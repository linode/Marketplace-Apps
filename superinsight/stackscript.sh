#!/usr/bin/bash

## REQUIRED IN EVERY MARKETPLACE SUBMISSION
# Add Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1
# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y
## END OF REQUIRED CODE FOR MARKETPLACE SUBMISSION

# Install docker
curl -fsSL get.docker.com | sudo sh

# Creating Password
echo "Superinsight setting up password...."
ADMIN_PASSWORD=$(openssl rand -hex 12)
NODE_IP=$(hostname -I | cut -f1 -d' ')
echo "Downloading and Installing Superinsight instance......"

# Install Superinsight
docker run \
--name superinsight-db-standalone \
--restart always \
-p 5432:5432 \
-v vol-superinsight:/db \
-e SUPERINSIGHT_USER=admin \
-e SUPERINSIGHT_PASSWORD="${ADMIN_PASSWORD}" \
superinsight/superinsight-db-standalone:latest


# Print instructions
cat << EOF > /etc/motd

################################################################################################################################################
																	SUPERINSIGHT
################################################################################################################################################

Superinsight created the user admin with password: ${ADMIN_PASSWORD}
You can can connect using a database client with the following connection string postgres://admin:${ADMIN_PASSWORD}@${NODE_IP}:5432/superinsight
For complete source code and information, visit: https://github.com/superinsight/superinsight-db

################################################################################################################################################
EOF
