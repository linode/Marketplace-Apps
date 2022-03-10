#!/bin/bash

# <UDF name="hostname" label="Hostname" />

source <ssinclude StackScriptID="1">

system_set_hostname "$HOSTNAME"

exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

apt update && apt upgrade -y && apt install -y curl wget net-tools traceroute jq
# Generate files
mkdir -p /etc/victoriametrics/single
mkdir -p /var/lib/victoria-metrics-data
mkdir -p /var/lib/cloud/scripts/per-instance

# Create victoriametrics user
groupadd -r victoriametrics
useradd -g victoriametrics -d /var/lib/victoria-metrics-data -s /sbin/nologin --system victoriametrics
chown -R victoriametrics:victoriametrics /var/lib/victoria-metrics-data

# Install VictoriaMetrics Single
VM_VERSION=`curl -sg "https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/tags" | jq -r '.[0].name'`
wget https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/${VM_VERSION}/victoria-metrics-amd64-${VM_VERSION}.tar.gz  -O /tmp/victoria-metrics.tar.gz
tar xvf /tmp/victoria-metrics.tar.gz -C /usr/bin
chmod +x /usr/bin/victoria-metrics-prod
chown root:root /usr/bin/victoria-metrics-prod

cat <<END >/etc/systemd/system/vmsingle.service
[Unit]
Description=VictoriaMetrics is a fast, cost-effective and scalable monitoring solution and time series database.
# https://docs.victoriametrics.com
After=network.target

[Service]
Type=simple
User=victoriametrics
Group=victoriametrics
WorkingDirectory=/var/lib/victoria-metrics-data
StartLimitBurst=5
StartLimitInterval=0
Restart=on-failure
RestartSec=5
EnvironmentFile=-/etc/victoriametrics/single/victoriametrics.conf
ExecStart=/usr/bin/victoria-metrics-prod \$ARGS
ExecStop=/bin/kill -s SIGTERM \$MAINPID
ExecReload=/bin/kill -HUP \$MAINPID
# See docs https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#tuning
ProtectSystem=full
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=vmsingle

[Install]
WantedBy=multi-user.target
END

cat <<END >/etc/victoriametrics/single/victoriametrics.conf
# See https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#list-of-command-line-flags to get more information about supported command-line flags
# 
# If you use IPv6 pleas add "-enableTCP6" to args line
ARGS="-promscrape.config=/etc/victoriametrics/single/scrape.yml -storageDataPath=/var/lib/victoria-metrics-data -retentionPeriod=12 -httpListenAddr=:8428 -graphiteListenAddr=:2003 -opentsdbListenAddr=:4242 -influxListenAddr=:8089 -enableTCP6"
END

cat <<END /etc/victoriametrics/single/scrape.yml
# Scrape config example
#
scrape_configs:
  - job_name: self_scrape
    scrape_interval: 10s
    static_configs:
      - targets: ['127.0.0.1:8428'] 
END

cat <<END >/etc/profile.d/victoriametrics_welcome.sh
#!/bin/sh
#
myip=$(hostname -I | awk '{print$1}')
cat <<
********************************************************************************
Welcome to VictoriaMetrics Single.
To keep this server secure, the UFW firewall is enabled.
All ports are BLOCKED except 22 (SSH), 80 (HTTP), and 443 (HTTPS), 8428 (VictoriaMetrics HTTP), 8089 (VictoriaMetrics Influx),
4242 (VictoriaMetrics OpenTSDB), 2003 (VictoriaMetrics Graphite)
In a web browser, you can view:
 * The VictoriaMetrics Quickstart guide: https://kutt.it/1click-quickstart
On the server:
  * The default VictoriaMetrics root is located at /var/lib/victoria-metrics-data
  * VictoriaMetrics is running on ports: 8428, 8089, 4242, 2003 and they are bound to the local interface.
********************************************************************************
  # This image includes version v1.74.0 of VictoriaMetrics. 
  # See Release notes https://github.com/VictoriaMetrics/VictoriaMetrics/releases/tag/v1.70.0

  # Welcome to VictoriaMetrics droplet!
  # Website:       https://victoriametrics.com
  # Documentation: https://docs.victoriametrics.com
  # VictoriaMetrics Github : https://github.com/VictoriaMetrics/VictoriaMetrics
  # VictoriaMetrics Slack Community: https://slack.victoriametrics.com
  # VictoriaMetrics Telegram Community: https://t.me/VictoriaMetrics_en
  # VictoriaMetrics config:   /etc/victoriametrics/single/victoriametrics.conf
  # VictoriaMetrics scrape config:   /etc/victoriametrics/single/scrape.yml
  # VictoriaMetrics UI accessable on:   http://your_droplet_public_ipv4:8428/vmui/
END

# Enable UFW and add some rules to it
sed -e 's|DEFAULT_FORWARD_POLICY=.*|DEFAULT_FORWARD_POLICY="ACCEPT"|g' \
    -i /etc/default/ufw

ufw allow ssh comment "SSH port"
ufw allow http comment "HTTP port"
ufw allow https comment "HTTPS port"
ufw allow 8428 comment "VictoriaMetrics Single HTTP port"
ufw allow 8089/tcp comment "TCP Influx Listen port for VictoriaMetrics"
ufw allow 8089/udp comment "UDP Influx Listen port for VictoriaMetrics"
ufw allow 2003/tcp comment "TCP Graphite Listen port for VictoriaMetrics"
ufw allow 2003/udp comment "UDP Graphite Listen port for VictoriaMetrics"
ufw allow 4242 comment "OpenTSDB Listen port for VictoriaMetrics"

ufw --force enable

# Cleaning up
rm -rf /tmp/* /var/tmp/*
history -c
cat /dev/null > /root/.bash_history
unset HISTFILE
find /var/log -mtime -1 -type f ! -name 'stackscript.log' -exec truncate -s 0 {} \;

# Start VictoriaMetrics
systemctl enable vmsingle.service
systemctl start vmsingle.service


echo "Installation complete!"