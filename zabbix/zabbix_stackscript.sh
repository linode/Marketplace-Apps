#!/bin/bash

# <UDF name="hostname" label="Hostname" />

source <ssinclude StackScriptID="1">

system_set_hostname "$HOSTNAME"

exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

# Generate files
mkdir -p /etc/my.cnf.d/
mkdir -p /etc/opt/rh/rh-nginx116/nginx/conf.d/
mkdir -p /etc/opt/rh/rh-php72/php-fpm.d/
mkdir -p /etc/opt/rh/rh-php72/php.d/
mkdir -p /etc/opt/profile.d/
mkdir -p /etc/zabbix/web/
mkdir -p /var/lib/cloud/scripts/per-instance

cat <<END >/etc/my.cnf.d/zabbix.cnf
[mysqld]
user = mysql
local_infile = 0
symbolic_links = 0
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
query_cache_type = 0
open_files_limit = 65535
wait_timeout = 86400
optimizer_switch=index_condition_pushdown=off
tmp_table_size = 32M
max_heap_table_size = 32M
binlog_format=mixed
binlog_cache_size = 32M
max_binlog_size = 256M
expire_logs_days = 3
innodb_buffer_pool_size = 256M
innodb_log_file_size = 128M
innodb_log_buffer_size = 64M
innodb_file_per_table = 1
innodb_flush_method = O_DIRECT
innodb_buffer_pool_instances = 4
innodb_write_io_threads = 4
innodb_read_io_threads = 4
innodb_adaptive_flushing = 1
innodb_lock_wait_timeout = 50
innodb_flush_log_at_trx_commit = 2
innodb_io_capacity = 300
innodb_io_capacity_max = 400
innodb_flush_neighbors = 0
innodb_checksums = 1
innodb_doublewrite = 1
innodb_support_xa = 0
innodb_thread_concurrency = 0
innodb_purge_threads = 1
gtid_domain_id = 1
server_id = 1
binlog_checksum = crc32
innodb_lru_scan_depth = 512
innodb_stats_on_metadata = 0
innodb_stats_sample_pages = 32
END

cat <<END >/etc/opt/rh/rh-nginx116/nginx/conf.d/zabbix_ssl.conf
server {
    listen          0.0.0.0:443 ssl http2;
    server_name     zabbix;
    index           index.php;
 
    set \$webroot '/usr/share/zabbix';
 
    access_log      /var/opt/rh/rh-nginx116/log/nginx/zabbix_access_ssl.log main;
    error_log       /var/opt/rh/rh-nginx116/log/nginx/zabbix_error_ssl.log error;
 
    # ssl_stapling         on;
 
    ssl_certificate      /etc/ssl/certs/zabbix_example.crt;
    ssl_certificate_key  /etc/ssl/private/zabbix_example.key;
 
    ssl_dhparam /etc/ssl/private/zabbix_dhparam.pem;
 
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_verify_depth 3;
    ssl_ciphers kEECDH+AES128:kEECDH:kEDH:-3DES:kRSA+AES128:kEDH+3DES:DES-CBC3-SHA:!RC4:!aNULL:!eNULL:!MD5:!EXPORT:!LOW:!SEED:!CAMELLIA:!IDEA:!PSK:!SRP:!SSLv2;
    ssl_session_cache    shared:SSL:10m;
    ssl_session_timeout  10m;
    ssl_prefer_server_ciphers  on;
 
    add_header Strict-Transport-Security "max-age=31536000; includeSubdomains; preload";
    add_header Content-Security-Policy-Report-Only "default-src https:; script-src https: 'unsafe-eval' 'unsafe-inline'; style-src https: 'unsafe-inline'; img-src https: data:; font-src https: data:; report-uri /csp-report";
 
    root \$webroot;
 
    charset utf8;
 
    large_client_header_buffers 8 8k;
 
    client_max_body_size 10M;
 
    location = /favicon.ico {
        log_not_found off;
    }
    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }
    # deny running scripts inside writable directories
    location ~* /(images|cache|media|logs|tmp)/.*\.(php|pl|py|jsp|asp|sh|cgi)$ {
        return 403;
        error_page 403 /403_error.html;
    }
    # Deny all attempts to access hidden files such as .htaccess, .htpasswd, .DS_Store (Mac).
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
    # caching of files
    location ~* \.(ico|pdf|flv)\$ {
        expires 1y;
    }
    location ~* \.(js|css|png|jpg|jpeg|gif|swf|xml|txt)\$ {
        expires 14d;
    }
    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }
    location ~ .php\$ {
        fastcgi_pass   unix:/var/opt/rh/rh-php72/run/php-fpm/zabbix.sock;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  \$webroot\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_param  QUERY_STRING     \$query_string;
        fastcgi_param  REQUEST_METHOD   \$request_method;
        fastcgi_param  CONTENT_TYPE     \$content_type;
        fastcgi_param  CONTENT_LENGTH   \$content_length;
        fastcgi_intercept_errors        on;
        fastcgi_ignore_client_abort     off;
        fastcgi_connect_timeout 60;
        fastcgi_send_timeout 180;
        fastcgi_read_timeout 180;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 4 256k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
    }
}
END

cat <<END >/etc/opt/rh/rh-nginx116/nginx/conf.d/zabbix.conf
server {
    listen          0.0.0.0:80;
    server_name zabbix;
    return 301 https://\$host\$request_uri;
}
END

cat <<END >/etc/opt/rh/rh-nginx116/nginx/nginx.conf
user nginx;
worker_processes 5;
worker_rlimit_nofile 256000;
error_log /var/opt/rh/rh-nginx116/log/nginx/error.log warn;
pid        /var/opt/rh/rh-nginx116/run/nginx/nginx.pid;
events {
    worker_connections 5120;
    use epoll;
}
http {
    include       /etc/opt/rh/rh-nginx116/nginx/mime.types;
    default_type  application/octet-stream;
    log_format main '\$remote_addr - \$remote_user [$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log /var/opt/rh/rh-nginx116/log/nginx/access.log main;
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
    gzip_types                      text/plain;
    gzip_types                      application/x-javascript;
    gzip_types                      text/css;
    output_buffers                  128 512k;
    postpone_output                 1460;
    aio                             on;
    directio                        512;
    sendfile                        on;
    client_max_body_size            8m;
    client_body_buffer_size         256k;
    fastcgi_intercept_errors        on;
    tcp_nopush                      on;
    tcp_nodelay                     on;
    keepalive_timeout               75 20;
    ignore_invalid_headers          on;
    index                           index.php;
    server_tokens                   off;
    include /etc/opt/rh/rh-nginx116/nginx/conf.d/*.conf;
}
END

cat <<END >/etc/opt/rh/rh-php72/php-fpm.d/zabbix.conf
[zabbix]
user = apache
group = apache
listen = /var/opt/rh/rh-php72/run/php-fpm/zabbix.sock
listen.acl_users = apache,nginx
;listen.allowed_clients = 127.0.0.1
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
php_value[session.save_handler] = files
php_value[session.save_path]    = /var/opt/rh/rh-php72/lib/php/session/
php_value[max_execution_time] = 300
php_value[memory_limit] = 128M
php_value[post_max_size] = 16M
php_value[upload_max_filesize] = 2M
php_value[max_input_time] = 300
php_value[max_input_vars] = 10000
; php_value[date.timezone] = Europe/Riga
END

cat <<END >/etc/opt/rh/rh-php72/php.d/99-zabbix.ini
max_execution_time=300
memory_limit=128M
post_max_size=16M
upload_max_filesize=2M
max_input_time=300
always_populate_raw_post_data=-1
max_input_vars=10000
date.timezone=UTC
session.save_path=/var/lib/php/
END

cat <<END >/etc/profile.d/zabbix_welcome.sh
#!/bin/sh
#
myip=\$(hostname -I | awk '{print\$1}')
cat <<EOF
********************************************************************************
Zabbix frontend credentials:
Username: Admin
Password: replace_password
To learn about available professional services, including technical suppport and training, please visit https://www.zabbix.com/services
Official Zabbix documentation available at https://www.zabbix.com/documentation/current/
Note! Do not forget to change timezone PHP variable in /etc/php.d/99-zabbix.ini file.
********************************************************************************
EOF
END

# cat <<END >/etc/systemd/system/zabbix-instance-init.service
# [Unit]
# After=mariadb.service

# [Service]
# ExecStart=/var/lib/cloud/scripts/per-instance/001-zabbix

# [Install]
# WantedBy=multi-user.target
# END

cat <<END >/etc/yum.repos.d/MariaDB.repo
# MariaDB 10.3 CentOS repository list - created 2019-03-28 10:57 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.2/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
END

cat <<END >/etc/yum.repos.d/Nginx.repo
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/\$releasever/\$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
END

cat <<END >/etc/zabbix/web/zabbix.conf.php
<?php
// Zabbix GUI configuration file.
global \$DB, \$HISTORY;
\$DB['TYPE']                             = 'MYSQL';
\$DB['SERVER']                   = 'localhost';
\$DB['PORT']                             = '0';
\$DB['DATABASE']                 = 'zabbix';
\$DB['USER']                             = 'replace_user';
\$DB['PASSWORD']                 = 'replace_password';
// Schema name. Used for IBM DB2 and PostgreSQL.
\$DB['SCHEMA']                   = '';
\$ZBX_SERVER                             = 'localhost';
\$ZBX_SERVER_PORT                = '10051';
\$ZBX_SERVER_NAME                = 'replace_name';
\$IMAGE_FORMAT_DEFAULT   = IMAGE_FORMAT_PNG;
// Uncomment this block only if you are using Elasticsearch.
// Elasticsearch url (can be string if same url is used for all types).
//\$HISTORY['url']   = [
//              'uint' => 'http://localhost:9200',
//              'text' => 'http://localhost:9200'
//];
// Value types stored in Elasticsearch.
//\$HISTORY['types'] = ['uint', 'text'];
END

cat <<END >/tmp/zabbix_server_custom.te
module zabbix_server_custom 1.0;
require {
        type zabbix_var_run_t;
        type zabbix_t;
        class sock_file { create unlink };
        class unix_stream_socket connectto;
}
#============= zabbix_t ==============
#!!!! The file '/run/zabbix/zabbix_server_alerter.sock' is mislabeled on your system.
#!!!! Fix with \$ restorecon -R -v /run/zabbix/zabbix_server_alerter.sock
#!!!! This avc can be allowed using the boolean 'daemons_enable_cluster_mode'
allow zabbix_t self:unix_stream_socket connectto;
allow zabbix_t zabbix_var_run_t:sock_file { create unlink };
END

# Installing RPM packages
yum makecache
yum -y upgrade
yum -y install http://repo.zabbix.com/zabbix/5.0/rhel/7/x86_64/zabbix-release-5.0-1.el7.noarch.rpm
yum -y install centos-release-scl
sed -i '/^\[zabbix-frontend\]$/,/^\[/ s/^enabled=0/enabled=1/' /etc/yum.repos.d/zabbix.repo
yum -y upgrade
yum -y install firewalld centos-release-scl mariadb-server java-1.8.0-openjdk-headless zabbix-server-mysql-5.0.1 zabbix-web-mysql-5.0.1 zabbix-agent-5.0.1 zabbix-get-5.0.1 zabbix-sender-5.0.1 zabbix-java-gateway-5.0.1 zabbix-web-mysql-scl zabbix-nginx-conf-scl

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

# Generate SSL certificate
mkdir -p /etc/ssl/private
openssl dhparam -out /etc/ssl/private/zabbix_dhparam.pem 2048
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/zabbix_example.key \
    -out /etc/ssl/certs/zabbix_example.crt -subj "/C=LV/ST=Riga/L=Riga/O=Global Security/OU=IT Department/CN=example.zabbix.com"

# Configure Zabbix instance
sed -i 's/^#PrintMotd yes/&\nPrintMotd no/g' /etc/ssh/sshd_config
zbx_version=$(zabbix_server -V | head -n1 | awk '{print $3}')

systemctl enable mariadb
systemctl enable zabbix-agent
systemctl enable rh-nginx116-nginx
systemctl enable rh-php72-php-fpm
systemctl enable zabbix-server
systemctl enable zabbix-java-gateway

systemctl start mariadb

# Generate database 'root' password
DB_ROOT_PASS=$(openssl rand 14 -base64)
DB_ROOT_PASS=${DB_ROOT_PASS%?}
# Generate Zabbix password to database
DB_ZBX_PASS=$(openssl rand 14 -base64)
DB_ZBX_PASS=${DB_ZBX_PASS%?}
WEB_PASS=$(openssl rand 14 -base64)
WEB_PASS=${WEB_PASS%?}
INST_NAME=$(hostname)

/usr/bin/mysqladmin -u root password "$DB_ROOT_PASS"
mysql -u root -p$DB_ROOT_PASS -e "CREATE DATABASE zabbix CHARACTER SET 'utf8' COLLATE 'utf8_bin'"
mysql -u root -p$DB_ROOT_PASS -e "CREATE USER 'zabbix_srv'@'localhost' IDENTIFIED BY '$DB_ZBX_PASS'"
mysql -u root -p$DB_ROOT_PASS -e "GRANT SELECT, UPDATE, DELETE, INSERT, CREATE, DROP, ALTER, INDEX, REFERENCES ON zabbix.* TO 'zabbix_srv'@'localhost'"
mysql -u root -p$DB_ROOT_PASS -e "CREATE USER 'zabbix_web'@'localhost' IDENTIFIED BY '$DB_ZBX_PASS'"
mysql -u root -p$DB_ROOT_PASS -e "GRANT SELECT, UPDATE, DELETE, INSERT, CREATE, DROP ON zabbix.* TO 'zabbix_web'@'localhost'"

cat > /root/.my.cnf << EOF
[client]
password="$DB_ROOT_PASS"
EOF

zcat /usr/share/doc/zabbix-server-mysql-$zbx_version/create.sql.gz | mysql -uroot -p$DB_ROOT_PASS zabbix

mysql -u root -p$DB_ROOT_PASS -e "UPDATE users SET passwd = MD5('$WEB_PASS') WHERE alias = 'Admin'" zabbix

sed -i "s~replace_password~$WEB_PASS~g" /etc/profile.d/zabbix_welcome.sh

sed -i "s/replace_name/$INST_NAME/g" /etc/zabbix/web/zabbix.conf.php

sed -i 's/^# JavaGateway=.*/&\nJavaGateway=127.0.0.1/g' /etc/zabbix/zabbix_server.conf
sed -i 's/^# StartJavaPollers=.*/&\nStartJavaPollers=5/g' /etc/zabbix/zabbix_server.conf
sed -i "s/^DBUser=.*/DBUser=zabbix_srv/g" /etc/zabbix/zabbix_server.conf
sed -i "s~^# DBPassword=.*~&\nDBPassword=$DB_ZBX_PASS~g" /etc/zabbix/zabbix_server.conf
sed -i "s~replace_password~$DB_ZBX_PASS~g" /etc/zabbix/web/zabbix.conf.php
sed -i "s/replace_user/zabbix_web/g" /etc/zabbix/web/zabbix.conf.php
sed -i 's/^# LISTEN_IP=.*/&\nLISTEN_IP="127.0.0.1"/g' /etc/zabbix/zabbix_java_gateway.conf

# Cleaning up
rm -rf /tmp/* /var/tmp/*
history -c
cat /dev/null > /root/.bash_history
unset HISTFILE
find /var/log -mtime -1 -type f ! -name 'stackscript.log' -exec truncate -s 0 {} \;

# Start Zabbix
systemctl start rh-nginx116-nginx rh-php72-php-fpm
systemctl start zabbix-server
systemctl start zabbix-agent
systemctl start zabbix-java-gateway

echo "Installation complete!"