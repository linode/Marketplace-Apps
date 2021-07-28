#!/bin/bash

# Add Logging to /var/log/stackscript.log for future troubleshooting
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# apt-get updates
 echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4
 export DEBIAN_FRONTEND=noninteractive
 apt-get update -y

wget https://cloudron.io/cloudron-setup
chmod +x cloudron-setup
./cloudron-setup --provider linode-mp

echo All finished! Rebooting...
(sleep 5; reboot) &