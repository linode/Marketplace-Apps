#!/bin/bash

# Author: licess <admin@lnmp.org>
# https://lnmp.org & https://lnmp.com
# version: 1.8
# date: 2021.6.1

exec 1> >(tee -a "/root/stackscript.log") 2>&1

#<UDF name="uStack" Label="Choose Stack" default="lnmp" oneOf="lnmp,lnmpa,lamp" />
#<UDF name="uDBSelect" Label="Database Version" default="MySQL 5.5" oneOf="MySQL 5.1,MySQL 5.5,MySQL 5.6,MySQL 5.7,MySQL 8.0,MariaDB 5.5,MariaDB 10.1,MariaDB 10.2,MariaDB 10.3,MariaDB 10.4,NO" example="default: MySQL 5.5" />
#<UDF name="DB_Root_Password" Label="Database Password" default="" />
#<UDF name="uInstallInnodb" Label="Enable InnoDB?" oneOf="yes,no" default="yes" />
#<UDF name="uPHPSelect" Label="PHP Version" oneOf="PHP 5.2,PHP 5.3,PHP 5.4,PHP 5.5,PHP 5.6,PHP 7.0,PHP 7.1,PHP 7.2,PHP 7.3,PHP 7.4,PHP 8.0" default="PHP 5.6" />
#<UDF name="uSelectMalloc" Label="Memory Allocator" oneOf="NO,Jemalloc,TCMalloc" default="NO" />
#<UDF name="uApacheSelect" Label="Apache Version for LNMPA or LAMP Stack" oneOf="Apache 2.2,Apache 2.4" default="Apache 2.4" />
#<UDF name="ServerAdmin" Label="Admin Mail for LNMPA or LAMP Stack" default="webmaster@example.com" />

if [ "$UDBSELECT" = "MySQL 5.1" ]; then
    DBSelect="1"
elif [ "$UDBSELECT" = "MySQL 5.5" ]; then
    DBSelect="2"
elif [ "$UDBSELECT" = "MySQL 5.6" ]; then
    DBSelect="3"
elif [ "$UDBSELECT" = "MySQL 5.7" ]; then
    DBSelect="4"
elif [ "$UDBSELECT" = "MySQL 8.0" ]; then
    DBSelect="5"
elif [ "$UDBSELECT" = "MariaDB 5.5" ]; then
    DBSelect="6"
elif [ "$UDBSELECT" = "MariaDB 10.1" ]; then
    DBSelect="7"
elif [ "$UDBSELECT" = "MariaDB 10.2" ]; then
    DBSelect="8"
elif [ "$UDBSELECT" = "MariaDB 10.3" ]; then
    DBSelect="9"
elif [ "$UDBSELECT" = "MariaDB 10.4" ]; then
    DBSelect="10"
elif [ "$UDBSELECT" = "NO" ]; then
    DBSelect="0"
fi

if [ "$UINSTALLINNODB" = "yes" ]; then
    InstallInnodb="y"
elif  [ "$UINSTALLINNODB" = "no" ]; then
    InstallInnodb="n"
fi

if [ "$UPHPSELECT" = "PHP 5.2" ]; then
    PHPSelect="1"
elif [ "$UPHPSELECT" = "PHP 5.3" ]; then
    PHPSelect="2"
elif [ "$UPHPSELECT" = "PHP 5.4" ]; then
    PHPSelect="3"
elif [ "$UPHPSELECT" = "PHP 5.5" ]; then
    PHPSelect="4"
elif [ "$UPHPSELECT" = "PHP 5.6" ]; then
    PHPSelect="5"
elif [ "$UPHPSELECT" = "PHP 7.0" ]; then
    PHPSelect="6"
elif [ "$UPHPSELECT" = "PHP 7.1" ]; then
    PHPSelect="7"
elif [ "$UPHPSELECT" = "PHP 7.2" ]; then
    PHPSelect="8"
elif [ "$UPHPSELECT" = "PHP 7.3" ]; then
    PHPSelect="9"
elif [ "$UPHPSELECT" = "PHP 7.4" ]; then
    PHPSelect="10"
elif [ "$UPHPSELECT" = "PHP 8.0" ]; then
    PHPSelect="11"
fi

if [ "$USELECTMALLOC" = "NO" ]; then
    SelectMalloc="1"
elif [ "$USELECTMALLOC" = "Jemalloc" ]; then
    SelectMalloc="2"
elif [ "$USELECTMALLOC" = "TCMalloc" ]; then
    SelectMalloc="3"
fi

if [ "$UAPACHESELECT" = "Apache 2.2" ]; then
    ApacheSelect="1"
elif [ "$UAPACHESELECT" = "Apache 2.4" ]; then
    ApacheSelect="2"
fi

echo "Installing dependent packages..."
if [ -f /etc/apt/sources.list ]; then
    apt-get update -y
    for packages in debian-keyring debian-archive-keyring wget screen curl tar;
    do apt-get --no-install-recommends install -y $packages; done
elif [ -f /etc/yum.conf ]; then
    for packages in wget screen curl tar;
    do yum -y install $packages; done
fi

cd /root/
wget http://soft.vpser.net/lnmp/lnmp1.8.tar.gz -cO lnmp1.8.tar.gz && tar zxf lnmp1.8.tar.gz
cd /root/lnmp1.8 && LNMP_Auto="y" DBSelect=$DBSelect DB_Root_Password=$DB_ROOT_PASSWORD InstallInnodb=$InstallInnodb PHPSelect=$PHPSelect SelectMalloc=$SelectMalloc ApacheSelect=$ApacheSelect ServerAdmin=$SERVERADMIN ./install.sh $USTACK