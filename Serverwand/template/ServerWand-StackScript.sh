#!/bin/bash

# serverwand ssh key
mkdir -p /root/.ssh/
chmod 700 /root/.ssh/
curl https://serverwand.com/api/servers/connect > ~/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys