#!/bin/bash

## Enable logging
exec > /var/log/stackscript.log 2>&1
set -o pipefail

# Source the Linode Bash StackScript, API, and OCA Helper libraries
source <ssinclude StackScriptID=1>
source <ssinclude StackScriptID=632759>
source <ssinclude StackScriptID=401712>

# Source and run the New Linode Setup script for DNS/SSH configuration
source <ssinclude StackScriptID=666912>

## Linode Docker OCA
source <ssinclude StackScriptID=607433>

# Configure service file
cat <<END > /etc/systemd/system/peppermint.service
[Unit]
Description=Docker Compose Peppermint Application Service
Requires=peppermint.service
After=peppermint.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
ExecReload=/usr/local/bin/docker-compose up -d
WorkingDirectory=/etc/docker/compose/peppermint/

[Install]
WantedBy=multi-user.target
END

# Get Docker Composer file
mkdir -p /etc/docker/compose/peppermint/
cd /etc/docker/compose/peppermint/
wget https://raw.githubusercontent.com/Peppermint-Lab/Peppermint/master/docker-compose.yml

# Enable Peppermint daemon
systemctl daemon-reload
systemctl enable peppermint.service
systemctl start peppermint.service

# Stackscript Cleanup
rm /root/StackScript
rm /root/ssinclude*
echo "Installation complete!"