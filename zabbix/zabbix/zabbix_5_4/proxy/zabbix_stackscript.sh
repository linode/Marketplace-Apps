#!/bin/bash

# <UDF name="hostname" label="Hostname" />

source <ssinclude StackScriptID="1">

system_set_hostname "$HOSTNAME"

exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Generate files

mkdir -p /etc/motd.d/

cat <<END >/etc/motd.d/zabbix
********************************************************************************

To learn about available professional services, including technical suppport and training, please visit https://www.zabbix.com/services

Official Zabbix documentation available at https://www.zabbix.com/documentation/current/

********************************************************************************
END

cat <<END >/tmp/zabbix_proxy_custom.te
module zabbix_proxy_custom 1.0;

require {
    type zabbix_t;
    class capability dac_override;
    class unix_stream_socket connectto;
}

#============= zabbix_t ==============
allow zabbix_t self:capability dac_override;

#!!!! This avc can be allowed using the boolean 'daemons_enable_cluster_mode'
allow zabbix_t self:unix_stream_socket connectto;
END

# Installing RPM packages
yum makecache
yum -y upgrade
dnf -y install https://repo.zabbix.com/zabbix/5.4/rhel/8/x86_64/zabbix-release-5.4-1.el8.noarch.rpm
yum -y upgrade
yum -y install cloud-init cloud-utils-growpart firewalld java-1.8.0-openjdk-headless zabbix-proxy-sqlite3 zabbix-agent zabbix-get zabbix-sender zabbix-java-gateway zabbix-js

# Configure firewalld
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-service=ssh --zone=public
firewall-cmd --permanent --add-port=10051/tcp --zone=public
firewall-cmd --reload

# Configure SELinux
rm -rf /tmp/zabbix_proxy_custom.mod /tmp/zabbix_proxy_custom.pp
checkmodule -M -m -o /tmp/zabbix_proxy_custom.mod /tmp/zabbix_proxy_custom.te
semodule_package -o /tmp/zabbix_proxy_custom.pp -m /tmp/zabbix_proxy_custom.mod
semodule -i /tmp/zabbix_proxy_custom.pp

setsebool -P zabbix_can_network=1

# Configure Zabbix instance
systemctl enable zabbix-proxy
systemctl enable zabbix-agent
systemctl enable zabbix-java-gateway

sed -i 's/^# JavaGateway=.*/&\nJavaGateway=127.0.0.1/g' /etc/zabbix/zabbix_proxy.conf
sed -i 's/^# StartJavaPollers=.*/&\nStartJavaPollers=5/g' /etc/zabbix/zabbix_proxy.conf
sed -i "s/^DBName=.*/DBName=\/tmp\/zabbix_proxy\.sqlite3/g" /etc/zabbix/zabbix_proxy.conf
sed -i 's/^# LISTEN_IP=.*/&\nLISTEN_IP="127.0.0.1"/g' /etc/zabbix/zabbix_java_gateway.conf

sed -i 's/^#PrintMotd yes/&\nPrintMotd no/g' /etc/ssh/sshd_config

# Cleaning up remote machine
rm -rf /tmp/* /var/tmp/*
history -c
cat /dev/null > /root/.bash_history
unset HISTFILE
find /var/log -mtime -1 -type f ! -name 'stackscript.log' -exec truncate -s 0 {} \;



systemctl restart zabbix-proxy zabbix-java-gateway zabbix-agent

echo "Installation complete!"