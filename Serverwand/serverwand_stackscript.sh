#!/bin/bash

# Logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# serverwand ssh key
mkdir -p /root/.ssh/
chmod 700 /root/.ssh/
curl https://serverwand.com/api/servers/connect > ~/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys