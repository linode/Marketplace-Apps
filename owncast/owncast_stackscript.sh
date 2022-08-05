#!/usr/bin/bash
#<UDF name="server_hostname" label="Your public hostname for your Owncast server. Required for SSL/HTTPS." example="owncast.example.com" default="">
#<UDF name="email_address" label="Your email address. Required for SSL/HTTPS." example="me@example.com" default="">

## REQUIRED IN EVERY MARKETPLACE SUBMISSION
# Add Logging to /var/log/stackscript.log for future troubleshooting
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1
# System Updates updates
apt-get -o Acquire::ForceIPv4=true update -y
## END OF REQUIRED CODE FOR MARKETPLACE SUBMISSION

# Add owncast user
adduser owncast --disabled-password --gecos ""

# Install dependencies
apt-get install -y libssl-dev unzip curl

# Install Owncast
mkdir -p /opt/owncast
cd /opt/owncast || exit

curl -s https://owncast.online/install.sh | bash
chown -R owncast:owncast /opt/owncast

# Setup Owncast as a systemd service
cat >/etc/systemd/system/owncast.service <<EOF
[Unit]
Description=Owncast
[Service]
Type=simple
User=owncast
Group=owncast
WorkingDirectory=/opt/owncast/owncast
ExecStart=/opt/owncast/owncast/owncast
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

# Restart systemd to reload new Owncast config
systemd daemon-reload

# Start Owncast
systemctl enable owncast
systemctl start owncast

# Install Caddy
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --yes --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install caddy

# Configure Caddy for HTTPS proxying
if [ -n "$SERVER_HOSTNAME" ] && [ -n "$EMAIL_ADDRESS" ]; then

  cat >/etc/caddy/Caddyfile <<EOF
  ${SERVER_HOSTNAME} {
    reverse_proxy 127.0.0.1:8080
    encode gzip
    tls ${EMAIL_ADDRESS}
  }
EOF
  # Start Caddy
  systemctl enable caddy
  systemctl restart caddy
else
  echo -e "\033[1mOWNCAST INSTALL WARNING: \033[0mServer hostname and/or email not specified.  Skipping Caddy/SSL configuration."
fi

# Add MOTD
cat >/etc/motd <<EOF

 #######  ##      ## ##    ##  ######     ###     ######  ########
##     ## ##  ##  ## ###   ## ##    ##   ## ##   ##    ##    ##
##     ## ##  ##  ## ####  ## ##        ##   ##  ##          ##
##     ## ##  ##  ## ## ## ## ##       ##     ##  ######     ##
##     ## ##  ##  ## ##  #### ##       #########       ##    ##
##     ## ##  ##  ## ##   ### ##    ## ##     ## ##    ##    ##
 #######   ###  ###  ##    ##  ######  ##     ##  ######     ##

For help and documentation visit: htts://owncast.online/docs
Note: Owncast is installed in /opt/owncast/owncast and running
as the user: owncast
EOF

echo "Owncast setup complete! Access your instance at https://${SERVER_HOSTNAME} or http://$(hostname -I | cut -f1 -d' '):8080 if you have not configured your DNS yet."
