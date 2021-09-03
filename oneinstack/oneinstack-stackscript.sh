#!/bin/bash
#<UDF name="RUNUSER" label="Run User" default="www" example="Nginx and PHP-FPM process is run as run_user" />
#<UDF name="TIMEZONE" label="TimeZone" oneof="UTC,Asia/Shanghai"  default="UTC" />
#<UDF name="NGINX" label="Nginx" oneof ="DoNotInstall,Nginx,OpenResty"  default="Nginx" />
#<UDF name="PHP" label="PHP"  oneof="DoNotInstall,8.0,7.4,7.3,7.2,7.1,7.0,5.6,5.5,5.4,5.3"  default="7.4" />
#<UDF name="PHPEXTENSIONS" label="PHP Extensions"  manyof="DoNotInstall,zendguardloader,ioncube,sourceguardian,imagick,gmagick,fileinfo,imap,ldap,calendar,phalcon,yaf,yar,redis,memcached,memcache,mongodb,swoole,xdebug"  default="fileinfo,redis" />
#<UDF name="DB" label="DB" oneof ="DoNotInstall,MariaDB-10.6,MariaDB-10.5,MySQL-8.0,MySQL-5.7"  default="MariaDB-10.6" />
#<UDF name="DBROOTPWD" label="DB Root Password" default="oneinstack" />
#<UDF name="JDK" label="JDK" oneof="DoNotInstall,11.0,1.8,1.7"  default="DoNotInstall" />
#<UDF name="TOMCAT" label="Tomcat"  oneof="DoNotInstall,9.0,8.5"  default="DoNotInstall" />
#<UDF name="NODE" label="Install NodeJs?" oneof="yes,no" default="no" />
#<UDF name="PUREFTPD" label="Install Pure-FTPd?" oneof="yes,no" default="no" />
#<UDF name="PHPMYADMIN" label="Install phpMyAdmin?"  oneof="yes,no" default="no" />
#<UDF name="REDIS" label="Install Redis?" oneof="yes,no" default="no" />
#<UDF name="MEMCACHED" label="Install Memcached?" oneof="yes,no" default="no" />

# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 6+ Debian 8+ and Ubuntu 14+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
printf "
#######################################################################
#       OneinStack for CentOS/RedHat 6+ Debian 8+ and Ubuntu 14+      #
#       For more information please visit https://oneinstack.com      #
#######################################################################
"
# Check if user is root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

# nginx
if [ $NGINX == "Nginx" ]; then
    nginx_option=1
elif [ $NGINX == "OpenResty" ]; then
    nginx_option=2
fi
[ $NGINX != "DoNotInstall" ] && INSTALL_ARGS="--nginx_option $nginx_option"

# php
if [ $PHP == "8.0" ]; then
    php_option=10
elif [ $PHP == "7.4" ]; then
    php_option=9
elif [ $PHP == "7.3" ]; then
    php_option=8
elif [ $PHP == "7.2" ]; then
    php_option=7
elif [ $PHP == "7.1" ]; then
    php_option=6
elif [ $PHP == "7.0" ]; then
    php_option=5
elif [ $PHP == "5.6" ]; then
    php_option=4
elif [ $PHP == "5.5" ]; then
    php_option=3
elif [ $PHP == "5.4" ]; then
    php_option=2
elif [ $PHP == "5.3" ]; then
    php_option=1
fi
[ $PHP != "DoNotInstall" ] && INSTALL_ARGS="$INSTALL_ARGS --php_option $php_option"

# php extensions
[ -z "`echo $PHPEXTENSIONS | grep 'DoNotInstall'`" ] && INSTALL_ARGS="$INSTALL_ARGS --php_extensions $PHPEXTENSIONS"

# db
if [ $DB == "MariaDB-10.6" ]; then
    db_option=5
elif [ $DB == "MariaDB-10.5" ]; then
    db_option=6
elif [ $DB == "MySQL-8.0" ]; then
    db_option=1
elif [ $DB == "MySQL-5.7" ]; then
    db_option=2
fi
[ $DB != "DoNotInstall" ] && INSTALL_ARGS="--db_option $db_option --dbrootpwd $DBROOTPWD $INSTALL_ARGS"

# jdk
if [ $JDK == "11.0" ]; then
    jdk_option=1
elif [ $JDK == "1.8" ]; then
    jdk_option=2
elif [ $JDK == "1.7" ]; then
    jdk_option=3
fi
[ $JDK != "DoNotInstall" ] && INSTALL_ARGS="$INSTALL_ARGS --jdk_option $jdk_option $INSTALL_ARGS"

# tomcat
if [ $TOMCAT == "9.0" ]; then
    tomcat_option=1
elif [ $TOMCAT == "8.5" ]; then
    tomcat_option=2
fi
[ $TOMCAT != "DoNotInstall" ] && INSTALL_ARGS="$INSTALL_ARGS --tomcat_option $tomcat_option"

[ $NODE == "yes" ] && INSTALL_ARGS="$INSTALL_ARGS --node"
[ $PUREFTPD == "yes" ] && INSTALL_ARGS="$INSTALL_ARGS --pureftpd"
[ $PHPMYADMIN == "yes" ] && INSTALL_ARGS="$INSTALL_ARGS --phpmyadmin"
[ $REDIS == "yes" ] && INSTALL_ARGS="$INSTALL_ARGS --redis"
[ $MEMCACHED == "yes" ] && INSTALL_ARGS="$INSTALL_ARGS --memcached"

useradd ${RUNUSER}
cd /root
wget -c http://mirrors.linuxeye.com/oneinstack-full.tar.gz
tar xzf oneinstack-full.tar.gz
sed -i "s@timezone=.*@timezone=${TIMEZONE}@" ./oneinstack/options.conf
sed -i "s@=www@=${RUNUSER}@g" ./oneinstack/options.conf
if [ -e "/usr/bin/yum" ]; then
  yum clean all
elif [ -e "/usr/bin/apt-get" ]; then
  apt-get update
fi
./oneinstack/install.sh $INSTALL_ARGS
echo $INSTALL_ARGS > /root/oneinstack/install_args.txt
[ -e "/root/oneinstack-full.tar.gz" ] && rm -rf /root/oneinstack-full.tar.gz
