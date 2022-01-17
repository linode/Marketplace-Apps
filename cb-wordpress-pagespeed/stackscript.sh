#!/bin/bash

set -x

# <UDF name="new_username" label="Linux User Name" example="webdev" />
# <UDF name="new_password" label="Linux User Password" />
# <UDF name="website" label="Website Domain" example="example.com" />
# <UDF name="website_name" label="Wordpress Website Name" />
# <UDF name="website_username" label="Wordpress Admin Username" />
# <UDF name="website_password" label="Wordpress Admin Password" />
# <UDF name="website_email" label="Wordpress Admin Email" />
# <UDF name="website_locale" label="Wordpress Locale" example="Example: de_DE, nl_NL, ru_RU" default="en_US" />


# Add Logging to /var/log/stackscript.log for future troubleshooting
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1


WEBSITE=$(echo $WEBSITE | sed -e 's/^https\?:\/\///g' -e 's/\/$//')


adduser "$NEW_USERNAME" --disabled-password --gecos ""
echo "${NEW_USERNAME}:${NEW_PASSWORD}" | chpasswd
adduser "$NEW_USERNAME" sudo >/dev/null
adduser "$NEW_USERNAME" www-data >/dev/null
adduser www-data "$NEW_USERNAME" >/dev/null

apt-get update
apt-get install curl mc htop nano -y

################
# Webserver

mkdir -p /var/www/${WEBSITE}
chown ${NEW_USERNAME}:www-data /var/www/${WEBSITE}

apt-get remove apache2 apache2-bin -y
apt-get install nginx libssl-dev -y

echo "work in progress, please wait" > /var/www/html/index.html
echo "work in progress, please wait" > /var/www/${WEBSITE}/index.html

if [ ! -f /usr/lib/nginx/modules/ngx_pagespeed.so ]; then
  ! bash <(curl -f -L -sS https://ngxpagespeed.com/install) --nginx-version $(nginx -v 2>&1 | grep -Eo '[0-9]+\.[0-9]+\.[0-9]' --color=never) --dynamic-module --assume-yes --additional-nginx-configure-arguments '--prefix=/usr/share/nginx --conf-path=/etc/nginx/nginx.conf --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log --lock-path=/var/lock/nginx.lock --pid-path=/run/nginx.pid --modules-path=/usr/lib/nginx/modules --http-client-body-temp-path=/var/lib/nginx/body --http-fastcgi-temp-path=/var/lib/nginx/fastcgi --http-proxy-temp-path=/var/lib/nginx/proxy --http-scgi-temp-path=/var/lib/nginx/scgi --http-uwsgi-temp-path=/var/lib/nginx/uwsgi --with-compat --with-pcre-jit --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --with-http_auth_request_module --with-http_v2_module --with-http_dav_module --with-http_slice_module --with-threads --with-http_addition_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_sub_module --with-stream_ssl_module --with-mail_ssl_module'
fi

mkdir -p /var/cache/ngx_pagespeed/
chown www-data:www-data /var/cache/ngx_pagespeed/

# pagespeed conf

cat <<END >/etc/nginx/modules-enabled/50-mod-pagespeed.conf
load_module "modules/ngx_pagespeed.so";
END

cat <<END >/etc/nginx/conf.d/pagespeed.conf
pagespeed on;
pagespeed FileCachePath "/var/cache/ngx_pagespeed/";

pagespeed EnableFilters combine_css,combine_javascript,collapse_whitespace,insert_dns_prefetch,rewrite_css,rewrite_images,rewrite_javascript,recompress_jpeg,recompress_png,strip_image_meta_data,resize_images,extend_cache,extend_cache_css,extend_cache_images,extend_cache_scripts,make_google_analytics_async,insert_dns_prefetch; # defer_javascript

pagespeed ImplicitCacheTtlMs 2629746000;
pagespeed DisableRewriteOnNoTransform off;
pagespeed FetchHttps enable,allow_self_signed,allow_unknown_certificate_authority,allow_certificate_not_yet_valid;
pagespeed RespectXForwardedProto on;
pagespeed InlineResourcesWithoutExplicitAuthorization Script,Stylesheet;
pagespeed PermitIdsForCssCombining *;

pagespeed FileCacheSizeKb            1024000;
pagespeed FileCacheCleanIntervalMs   360000000;
pagespeed FileCacheInodeLimit        5000000;

pagespeed Domain https://${WEBSITE};
pagespeed Domain http://${WEBSITE};
pagespeed Domain https://www.${WEBSITE};
pagespeed Domain http://www.${WEBSITE};

pagespeed LoadFromFile "https://${WEBSITE}" "/var/www/${WEBSITE}/";
pagespeed LoadFromFile "http://${WEBSITE}" "/var/www/${WEBSITE}/";
pagespeed LoadFromFile "https://www.${WEBSITE}" "/var/www/${WEBSITE}/";
pagespeed LoadFromFile "http://www.${WEBSITE}" "/var/www/${WEBSITE}/";

pagespeed Disallow "*.svg*";
END

# domain conf

cat <<END >/etc/nginx/sites-enabled/${WEBSITE}.conf
server {
    listen 80;

    server_name ${WEBSITE} www.${WEBSITE};
    server_tokens off;

    client_max_body_size 80m;
    gzip_http_version 1.0;

    index index.html index.php;

    root /var/www/${WEBSITE};

    location = /favicon.ico {
        log_not_found off;
        access_log off;
    }

    location = /robots.txt {
        allow all;
        log_not_found off;
        access_log off;
    }

    location ~ \..*/.*\.php\$ {
        return 403;
    }

    # Allow "Well-Known URIs" as per RFC 5785
    location ~* ^/.well-known/ {
        allow all;
    }

    # Block access to "hidden" files and directories whose names begin with a
    # period. This includes directories used by version control systems such
    # as Subversion or Git to store control files.
    location ~ (^|/)\. {
        return 403;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~* /(?:wp/)?(?:uploads|files)/.*\.php\$ {
        deny all;
    }


    location ~ '\.php\$' {
        fastcgi_split_path_info ^(.+?\.php)(|/.*)\$;

        include fastcgi_params;

        fastcgi_read_timeout 300;
        fastcgi_buffer_size 32k;
        fastcgi_buffers 4 32k;

        # Block httpoxy attacks. See https://httpoxy.org/.
        fastcgi_param HTTP_PROXY "";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_param QUERY_STRING \$query_string;
        fastcgi_intercept_errors on;

        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|eot|ttf)\$ {
        add_header Access-Control-Allow-Origin * always;
        try_files \$uri @rewrite;
        expires max;
        log_not_found off;
    }
}

END

ln -s /etc/nginx/sites-enabled/${WEBSITE}.conf /etc/nginx/sites-available/


systemctl restart nginx.service


chgrp -R www-data /var/www
chmod -R g+w /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod ug+rw {} \;


################
# PHP

apt install php7.4-{cli,fpm,mysqlnd,pdo,xml,calendar,ctype,curl,dom,exif,fileinfo,gd,iconv,igbinary,imagick,mbstring,phar,posix,redis,msgpack,shmop,simplexml,sockets,sysvmsg,sysvsem,sysvshm,xmlreader,xmlwriter,xsl,zip,memcached} -y

sed -i -e 's/pm.max_children = 5$/pm.max_children = 50/g' /etc/php/7.4/fpm/pool.d/www.conf
sed -i -e 's/pm.max_spare_servers = 3$/pm.max_spare_servers = 30/g' /etc/php/7.4/fpm/pool.d/www.conf

sed -i -e 's/upload_max_filesize = 2M$/upload_max_filesize = 80M/g' /etc/php/7.4/fpm/php.ini
sed -i -e 's/post_max_size = 8M$/post_max_size = 80M/g' /etc/php/7.4/fpm/php.ini
sed -i -e 's/;max_input_vars = 1000$/max_input_vars = 10000/g' /etc/php/7.4/fpm/php.ini

systemctl restart php7.4-fpm.service


################
# MySQL


apt-get install mariadb-server -y


db_name="wordpress_$(</dev/urandom tr -dc A-Za-z0-9 | head -c 4)"
db_password="$(</dev/urandom tr -dc A-Za-z0-9 | head -c 12)"

echo "CREATE DATABASE $db_name;" | mysql
echo "CREATE USER '$db_name'@'localhost' IDENTIFIED BY '$db_password';" | mysql
echo "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_name'@'localhost';" | mysql
echo "FLUSH PRIVILEGES;" | mysql


################
# Redis

apt install redis-server -y

################
# WordPress

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

cd /var/www/${WEBSITE}
sudo -u $NEW_USERNAME wp core download --locale=$WEBSITE_LOCALE
sudo -u $NEW_USERNAME wp core config --dbname=$db_name --dbuser=$db_name --dbpass=$db_password
sudo -u $NEW_USERNAME wp core install --url=$WEBSITE --title=$WEBSITE_NAME --admin_user=$WEBSITE_USERNAME --admin_password=$WEBSITE_PASSWORD --admin_email=$WEBSITE_EMAIL

sudo -u $NEW_USERNAME wp plugin install wordpress-seo --activate
sudo -u $NEW_USERNAME wp plugin install w3-total-cache --activate
sudo -u $NEW_USERNAME wp plugin install wp-mail-smtp
sudo -u $NEW_USERNAME wp plugin install mailgun

sudo -u $NEW_USERNAME wp rewrite structure '/%postname%/'

sudo -u $NEW_USERNAME wp w3-total-cache option set objectcache.enabled true --type=boolean
sudo -u $NEW_USERNAME wp w3-total-cache option set objectcache.engine redis
sudo -u $NEW_USERNAME wp w3-total-cache option set pgcache.engine redis
sudo -u $NEW_USERNAME wp w3-total-cache option set common.hide_note_wp_content_permissions true --state --type=boolean
sudo -u $NEW_USERNAME wp w3-total-cache option set common.show_note.nginx_restart_required false --state --type=boolean

rm -f /var/www/html/index.html
rm -f /var/www/${WEBSITE}/index.html
