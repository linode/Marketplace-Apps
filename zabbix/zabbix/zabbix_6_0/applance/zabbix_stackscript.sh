#!/bin/bash

# <UDF name="hostname" label="Hostname" />

source <ssinclude StackScriptID="1">

system_set_hostname "$HOSTNAME"

exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Generate files
mkdir -p /etc/my.cnf.d/
mkdir -p /etc/nginx/conf.d/
mkdir -p /etc/php-fpm.d/
mkdir -p /etc/php.d/
# mkdir -p /etc/profile.d/
mkdir -p /etc/motd.d/
mkdir -p /etc/zabbix/web/
mkdir -p /var/lib/cloud/scripts/per-instance

cat <<END >/etc/my.cnf.d/zabbix.cnf
[mysqld]
user = mysql
local_infile = 0

datadir = /var/lib/mysql/

default-storage-engine = InnoDB
skip-name-resolve
key_buffer_size = 32M
max_allowed_packet = 128M
table_open_cache = 1024
table_definition_cache = 1024
max_connections = 2000
join_buffer_size = 1M
sort_buffer_size = 2M
read_buffer_size = 256K
read_rnd_buffer_size = 256K
myisam_sort_buffer_size = 1M
thread_cache_size = 512
open_files_limit = 10000
wait_timeout = 86400

optimizer_switch=index_condition_pushdown=off

tmp_table_size = 32M
max_heap_table_size = 32M

binlog_format=mixed
binlog_cache_size = 32M
max_binlog_size = 256M
binlog_expire_logs_seconds = 259200

# innodb_page_size = 32K
innodb_buffer_pool_size = 512M
innodb_log_file_size = 256M
innodb_log_buffer_size = 64M
innodb_file_per_table = 1
innodb_flush_method = O_DIRECT
innodb_buffer_pool_instances = 4
innodb_write_io_threads = 4
innodb_read_io_threads = 4
innodb_adaptive_flushing = 1
innodb_lock_wait_timeout = 50

innodb_flush_log_at_trx_commit = 1

innodb_io_capacity = 300
innodb_io_capacity_max = 400
innodb_flush_neighbors = 0

innodb_doublewrite = 1
innodb_thread_concurrency = 0

innodb_purge_threads = 1

server_id = 1
binlog_checksum = crc32

innodb_lru_scan_depth = 512

innodb_stats_on_metadata = 0

END

cat <<END >/etc/nginx/conf.d/zabbix_ssl.conf
server {
        listen          0.0.0.0:443 ssl http2;
        # server_name     <server_name>;
        index           index.php;

        root \$webroot;
        charset utf8;
        set \$webroot '/usr/share/zabbix';

        access_log      /var/log/nginx/zabbix_access_ssl.log main;
        error_log       /var/log/nginx/zabbix_error_ssl.log error;

        ssl_stapling         on;
        ssl_stapling_verify  on;

        #resolver             192.168.13.160 192.168.10.24;

        ssl_certificate      /etc/ssl/certs/zabbix_example.crt;
        ssl_certificate_key  /etc/ssl/private/zabbix_example.key;

        ssl_dhparam /etc/ssl/private/zabbix_dhparam.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_verify_depth 3;
        #ssl_ciphers  HIGH:!aNULL:!MD5;
        ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
        #ssl_session_cache    shared:SSL:10m;
        ssl_session_cache shared:MozSSL:10m;
        ssl_session_timeout  1d;
        ssl_prefer_server_ciphers  off;
        ssl_session_tickets off;

        add_header Strict-Transport-Security "max-age=63072000" always;
        add_header Content-Security-Policy-Report-Only "default-src https:; script-src https: 'unsafe-eval' 'unsafe-inline'; style-src https: 'unsafe-inline'; img-src https: data:; font-src https: data:; report-uri /csp-report";

        location = /favicon.ico {
                log_not_found off;
        }

        location / {
                index   index.php;
                try_files       \$uri \$uri/      =404;
        }

        location ~* ^.+.(js|css|png|jpg|jpeg|gif|ico)$ {
                access_log      off;
                expires         10d;
        }

        location ~ /\.ht {
                deny all;
        }

        location ~ /(api\/|conf[^\.]|include|locale) {
                deny all;
                return 404;
        }

        location ~ [^/]\.php(/|$) {
                fastcgi_pass    unix:/run/php-fpm/zabbix.sock;
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_index   index.php;

                fastcgi_param   DOCUMENT_ROOT   /usr/share/zabbix;
                fastcgi_param   SCRIPT_FILENAME /usr/share/zabbix\$fastcgi_script_name;
                fastcgi_param   PATH_TRANSLATED /usr/share/zabbix\$fastcgi_script_name;

                include fastcgi_params;
                fastcgi_param   QUERY_STRING    \$query_string;
                fastcgi_param   REQUEST_METHOD  \$request_method;
                fastcgi_param   CONTENT_TYPE    \$content_type;
                fastcgi_param   CONTENT_LENGTH  \$content_length;

                fastcgi_intercept_errors        on;
                fastcgi_ignore_client_abort     off;
                fastcgi_connect_timeout         60;
                fastcgi_send_timeout            180;
                fastcgi_read_timeout            180;
                fastcgi_buffer_size             128k;
                fastcgi_buffers                 4 256k;
                fastcgi_busy_buffers_size       256k;
                fastcgi_temp_file_write_size    256k;
        }
}

END

cat <<END >/etc/nginx/conf.d/zabbix.conf
server {
    listen          0.0.0.0:80;
    # server_name zabbix;

    return 301 https://\$host\$request_uri;
}

END

cat <<END >/etc/nginx/nginx.conf
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
worker_priority -5;
worker_rlimit_nofile 256000;

error_log  /var/log/nginx/error.log;

pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 5120;
    use epoll;
    multi_accept on;
}


http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main
            '\$http_x_forwarded_for - \$remote_user [\$time_local] '
            '"\$request" \$status \$bytes_sent '
            '"\$http_referer" "\$http_user_agent" '
            '"\$gzip_ratio"';

    access_log  /var/log/nginx/access.log  main;

    open_file_cache max=200000 inactive=20s;
    open_file_cache_valid 30s;
    open_file_cache_min_uses 2;
    open_file_cache_errors on;

    limit_conn_zone \$binary_remote_addr zone=perip:10m;
    limit_conn_zone \$server_name zone=perserver:10m;

    client_header_timeout           5m;
    client_body_timeout             5m;
    send_timeout                    5m;

    connection_pool_size            4096;
    client_header_buffer_size       4k;
    large_client_header_buffers     4 4k;
    request_pool_size               4k;

    reset_timedout_connection       on;


    gzip                            on;
    gzip_min_length                 100;
    gzip_buffers                    4 8k;
    gzip_comp_level                 5;
    gzip_types text/plain text/css text/xml application/x-javascript application/xml application/xhtml+xml;

    types_hash_max_size             2048;

    output_buffers                  128 512k;
    postpone_output                 1460;
    aio                             on;
    directio                        512;

    sendfile                        on;
    client_max_body_size            8m;
    fastcgi_intercept_errors        on;

    tcp_nopush                      on;
    tcp_nodelay                     on;

    keepalive_timeout               75 20;

    ignore_invalid_headers          on;

    index                           index.php;
    server_tokens                   off;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;
}

END

cat <<END >/etc/php-fpm.d/zabbix.conf
[zabbix]
user = apache
group = apache

listen = /run/php-fpm/zabbix.sock
listen.acl_users = apache,nginx
listen.allowed_clients = 127.0.0.1

pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35

php_value[session.save_handler] = files
php_value[session.save_path]    = /var/lib/php/session

php_value[max_execution_time] = 300
php_value[memory_limit] = 128M
php_value[post_max_size] = 16M
php_value[upload_max_filesize] = 2M
php_value[max_input_time] = 300
php_value[max_input_vars] = 10000
; php_value[date.timezone] = Europe/Riga
END

# cat <<END >/etc/php.d/99-zabbix.ini
# max_execution_time=300
# memory_limit=128M
# post_max_size=16M
# upload_max_filesize=2M
# max_input_time=300
# always_populate_raw_post_data=-1
# max_input_vars=10000
# date.timezone=UTC
# session.save_path=/var/lib/php/
# END

# cat <<END >/etc/profile.d/zabbix_welcome.sh
# #!/bin/sh
# #
# myip=\$(hostname -I | awk '{print\$1}')
# cat <<EOF
# ********************************************************************************
# Zabbix frontend credentials:
# Username: Admin
# Password: replace_password
# To learn about available professional services, including technical suppport and training, please visit https://www.zabbix.com/services
# Official Zabbix documentation available at https://www.zabbix.com/documentation/current/
# Note! Do not forget to change timezone PHP variable in /etc/php.d/99-zabbix.ini file.
# ********************************************************************************
# EOF
# END

cat <<END >/etc/motd.d/zabbix
********************************************************************************

Zabbix frontend credentials:

Username: Admin

Password: replace_password


To learn about available professional services, including technical suppport and training, please visit https://www.zabbix.com/services

Official Zabbix documentation available at https://www.zabbix.com/documentation/current/


********************************************************************************
END

# cat <<END >/etc/systemd/system/zabbix-instance-init.service
# [Unit]
# After=mariadb.service

# [Service]
# ExecStart=/var/lib/cloud/scripts/per-instance/001-zabbix

# [Install]
# WantedBy=multi-user.target
# END

# cat <<END >/etc/yum.repos.d/MariaDB.repo
# # MariaDB 10.3 CentOS repository list - created 2019-03-28 10:57 UTC
# # http://downloads.mariadb.org/mariadb/repositories/
# [mariadb]
# name = MariaDB
# baseurl = http://yum.mariadb.org/10.2/centos7-amd64
# gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
# gpgcheck=1
# END

cat <<END >/etc/yum.repos.d/Nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true
END

cat <<END >/etc/zabbix/web/zabbix.conf.php
<?php
// Zabbix GUI configuration file.

\$DB['TYPE']				= 'MYSQL';
\$DB['SERVER']			= 'localhost';
\$DB['PORT']				= '0';
\$DB['DATABASE']			= 'zabbix';
\$DB['USER']				= 'replace_user';
\$DB['PASSWORD']			= 'replace_password';

// Schema name. Used for PostgreSQL.
\$DB['SCHEMA']			= '';

// Used for TLS connection.
\$DB['ENCRYPTION']		= false;
\$DB['KEY_FILE']			= '';
\$DB['CERT_FILE']		= '';
\$DB['CA_FILE']			= '';
\$DB['VERIFY_HOST']		= false;
\$DB['CIPHER_LIST']		= '';

// Use IEEE754 compatible value range for 64-bit Numeric (float) history values.
// This option is enabled by default for new Zabbix installations.
// For upgraded installations, please read database upgrade notes before enabling this option.
\$DB['DOUBLE_IEEE754']	= true;

\$ZBX_SERVER				= 'localhost';
\$ZBX_SERVER_PORT		= '10051';
\$ZBX_SERVER_NAME		= 'replace_name';

\$IMAGE_FORMAT_DEFAULT	= IMAGE_FORMAT_PNG;

// Uncomment this block only if you are using Elasticsearch.
// Elasticsearch url (can be string if same url is used for all types).
//\$HISTORY['url'] = [
//	'uint' => 'http://localhost:9200',
//	'text' => 'http://localhost:9200'
//];
// Value types stored in Elasticsearch.
//\$HISTORY['types'] = ['uint', 'text'];

// Used for SAML authentication.
// Uncomment to override the default paths to SP private key, SP and IdP X.509 certificates, and to set extra settings.
//\$SSO['SP_KEY']			= 'conf/certs/sp.key';
//\$SSO['SP_CERT']			= 'conf/certs/sp.crt';
//\$SSO['IDP_CERT']		= 'conf/certs/idp.crt';
//\$SSO['SETTINGS']		= [];
END

cat <<END >/tmp/zabbix_server_custom.te
module zabbix_server_custom 1.2;
require {
        type zabbix_var_run_t;
        type tmp_t;
        type zabbix_t;
        class sock_file { create unlink write };
        class unix_stream_socket connectto;
        class process setrlimit;
        class capability dac_override;
}
#============= zabbix_t ==============
#!!!! This avc is allowed in the current policy
allow zabbix_t self:process setrlimit;
#!!!! This avc is allowed in the current policy
allow zabbix_t self:unix_stream_socket connectto;
#!!!! This avc is allowed in the current policy
allow zabbix_t tmp_t:sock_file { create unlink write };
#!!!! This avc is allowed in the current policy
allow zabbix_t zabbix_var_run_t:sock_file { create unlink write };
#!!!! This avc is allowed in the current policy
allow zabbix_t self:capability dac_override;
END

# Installing RPM packages
yum makecache
yum -y upgrade
dnf -y install https://dev.mysql.com/get/mysql80-community-release-el8-3.noarch.rpm
dnf -y module disable mysql
dnf -y install https://repo.zabbix.com/zabbix/6.0/rhel/8/x86_64/zabbix-release-6.0-1.el8.noarch.rpm
yum -y upgrade
yum -y install cloud-init cloud-utils-growpart firewalld nginx php-fpm mysql-community-client mysql-community-server java-1.8.0-openjdk-headless zabbix-server-mysql zabbix-web-mysql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent zabbix-get zabbix-sender zabbix-java-gateway zabbix-js


# Configure firewalld
systemctl enable firewalld
systemctl start firewalld
firewall-cmd --permanent --add-service=ssh --zone=public
firewall-cmd --permanent --add-service=http --zone=public
firewall-cmd --permanent --add-service=https --zone=public
firewall-cmd --permanent --add-port=10051/tcp --zone=public
firewall-cmd --reload

# Configure SELinux
rm -rf /tmp/zabbix_server_custom.mod /tmp/zabbix_server_custom.pp
checkmodule -M -m -o /tmp/zabbix_server_custom.mod /tmp/zabbix_server_custom.te
semodule_package -o /tmp/zabbix_server_custom.pp -m /tmp/zabbix_server_custom.mod
semodule -i /tmp/zabbix_server_custom.pp

setsebool -P httpd_can_connect_zabbix=1
setsebool -P zabbix_can_network=1

# Generate SSL certificate
mkdir -p /etc/ssl/private
openssl dhparam -out /etc/ssl/private/zabbix_dhparam.pem 2048

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/zabbix_example.key \
    -out /etc/ssl/certs/zabbix_example.crt -subj "/C=LV/ST=Riga/L=Riga/O=Global Security/OU=IT Department/CN=example.zabbix.com"

# Configure Zabbix instance
systemctl enable mysqld
systemctl disable nginx
systemctl disable php-fpm
systemctl disable zabbix-server
systemctl enable zabbix-agent
systemctl enable zabbix-java-gateway

systemctl stop nginx php-fpm

echo "Requires=multi-user.target" >> /usr/lib/systemd/system/cloud-init.target

systemctl set-default cloud-init.target

chown -R apache:apache /var/lib/php/

chmod g+r /etc/zabbix/zabbix_server.conf
chmod o+w /run/zabbix/

chmod 755 /etc/my.cnf
chmod -R 755 /etc/my.cnf.d/

sed -i 's/^#PrintMotd yes/&\nPrintMotd no/g' /etc/ssh/sshd_config

sed -i '/^; php_value\[date.timezone\] /s/^; //' /etc/php-fpm.d/zabbix.conf

sed -i 's/^# JavaGateway=.*/&\nJavaGateway=127.0.0.1/g' /etc/zabbix/zabbix_server.conf
sed -i 's/^# StartJavaPollers=.*/&\nStartJavaPollers=5/g' /etc/zabbix/zabbix_server.conf
sed -i 's/^# LISTEN_IP=.*/&\nLISTEN_IP="127.0.0.1"/g' /etc/zabbix/zabbix_java_gateway.conf

escape_spec_char() {
    local var_value=$1

    var_value="${var_value//\\/\\\\}"
    var_value="${var_value//[$'\n']/}"
    var_value="${var_value//\//\\/}"
    var_value="${var_value//./\\.}"
    var_value="${var_value//\*/\\*}"
    var_value="${var_value//^/\\^}"
    var_value="${var_value//\$/\\$}"
    var_value="${var_value//\&/\\&}"
    var_value="${var_value//\[/\\[}"
    var_value="${var_value//\]/\\]}"

    echo "$var_value"
}

systemctl start mysqld
systemctl enable mysqld
systemctl enable nginx
systemctl enable php-fpm
systemctl enable zabbix-server

DB_ROOT_TMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | awk '{print $13}' | tail -1)
WEB_PASS=$(openssl rand -base64 14)
WEB_PASS=${WEB_PASS%?}
INST_NAME=$(hostname)

rm -f /root/.my.cnf

DB_ROOT_PASS=$(MYSQL_PWD="$DB_ROOT_TMP_PASS" mysql --connect-expired-password -s -N -e "SET PASSWORD FOR root@localhost TO RANDOM;"  | awk '{print $3}')
DB_ZBX_PASS=$(MYSQL_PWD="$DB_ROOT_PASS" mysql -s -N -e "CREATE USER 'zabbix_srv'@'localhost' IDENTIFIED WITH mysql_native_password BY RANDOM PASSWORD"  | awk '{print $3}')
DB_ZBXWEB_PASS=$(MYSQL_PWD="$DB_ROOT_PASS" mysql -s -N -e "CREATE USER 'zabbix_web'@'localhost' IDENTIFIED WITH mysql_native_password BY RANDOM PASSWORD"  | awk '{print $3}')

MYSQL_PWD="$DB_ROOT_PASS" mysql -u root -e "CREATE DATABASE zabbix CHARACTER SET 'utf8' COLLATE 'utf8_bin'"
MYSQL_PWD="$DB_ROOT_PASS" mysql -u root -e "GRANT SELECT, UPDATE, DELETE, INSERT, CREATE, DROP, ALTER, INDEX, REFERENCES ON zabbix.* TO 'zabbix_srv'@'localhost'"
MYSQL_PWD="$DB_ROOT_PASS" mysql -u root -e "GRANT SELECT, UPDATE, DELETE, INSERT, CREATE, DROP ON zabbix.* TO 'zabbix_web'@'localhost'"

cat > /root/.my.cnf << EOF
[client]
password="$DB_ROOT_PASS"
EOF

zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | MYSQL_PWD="$DB_ROOT_PASS" mysql -uroot zabbix

MYSQL_PWD="$DB_ROOT_PASS" mysql -u root -e "UPDATE users SET passwd = MD5('$WEB_PASS') WHERE username  = 'Admin'" zabbix

WEB_PASS=$(escape_spec_char "$WEB_PASS")
sed -i "s/replace_password/$WEB_PASS/g" /etc/motd.d/zabbix

sed -i "s/replace_name/$INST_NAME/g" /etc/zabbix/web/zabbix.conf.php

DB_ZBX_PASS=$(escape_spec_char "$DB_ZBX_PASS")
DB_ZBXWEB_PASS=$(escape_spec_char "$DB_ZBXWEB_PASS")

sed -i "s/^DBUser=.*/DBUser=zabbix_srv/g" /etc/zabbix/zabbix_server.conf
sed -i -e "/^[#;] DBPassword=/s/.*/&\nDBPassword=$DB_ZBX_PASS/" /etc/zabbix/zabbix_server.conf
sed -i "s/replace_password/$DB_ZBXWEB_PASS/g" /etc/zabbix/web/zabbix.conf.php
sed -i "s/replace_user/zabbix_web/g" /etc/zabbix/web/zabbix.conf.php

# Cleaning up remote machine
rm -rf /etc/nginx/conf.d/default.conf
rm -rf /tmp/* /var/tmp/*
history -c
cat /dev/null > /root/.bash_history
unset HISTFILE
find /var/log -mtime -1 -type f ! -name 'stackscript.log' -exec truncate -s 0 {} \;



systemctl start zabbix-server zabbix-agent zabbix-java-gateway
systemctl start nginx php-fpm

echo "Installation complete!"