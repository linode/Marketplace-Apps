#!/bin/bash

echo -e "\n---------------HALTDOS COMMUNITY WAF SETUP---------------"

export NEEDRESTART_SUSPEND=1
ip=`ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}'`
echo -e "Checking OS ..."
source /etc/os-release > /dev/null 2>&1
arch=`uname -m`
if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
    if [[ "$VERSION_ID" == "18.04" || "$VERSION_ID" == "20.04" || "$VERSION_ID" == "22.04" || "$VERSION_ID" == "11" ]]; then
        if [ "$arch" != "x86_64" ]; then
            echo -e "\e[1;31m$arch is not yet supported. Supported System Architecture - x86_64 \e[0m"
        fi
    else
        echo -e "\e[1;31mThis OS is not yet supported. Supported OS - Ubuntu 18.04, 20.04, 22.04 and Debian 11 \e[0m"
        exit 1
    fi
else
    echo -e "\e[1;31mThis OS is not yet supported. Supported Versions - Ubuntu 18.04, 20.04, 22.04 and Debian 11 \e[0m"
    exit 1
fi

echo -e "Downloading dependencies ..."

apt-get update &> /dev/null

apt-get install -y default-jdk default-jre  &> /dev/null
echo "JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/" >> /etc/environment
source /etc/environment

echo -e "Downloading latest binaries ..."

source /etc/os-release > /dev/null 2>&1
if [ "$VERSION_ID" == "18.04" ]; then
    apt-get install -y libmaxminddb-dev python-dev python &> /dev/null 
    curl -s -k -o hd-community-waf.deb https://binary.haltdos.com/community/waf/deb/ubuntu-18/hd-community-waf-x86_64.deb &> /dev/null
elif [ "$VERSION_ID" == "20.04" ]; then
    apt-get install -y libmaxminddb-dev python-dev python &> /dev/null
    curl -s -k -o hd-community-waf.deb https://binary.haltdos.com/community/waf/deb/ubuntu-20/hd-community-waf-x86_64.deb &> /dev/null
elif [ "$VERSION_ID" == "22.04" ]; then
    apt-get install -y libmaxminddb-dev libmaxminddb0 mmdb-bin python2-dev python2 &> /dev/null
    curl -s -k -o hd-community-waf.deb https://binary.haltdos.com/community/waf/deb/ubuntu-22/hd-community-waf-x86_64.deb &> /dev/null
elif [[ "$ID" == "debian" && "$VERSION_ID" == "11" ]]; then
    apt-get install -y sudo libmaxminddb-dev python-dev python &> /dev/null
    curl -s -k -o hd-community-waf.deb https://binary.haltdos.com/community/waf/deb/debian-11/hd-community-waf-x86_64.deb &> /dev/null
fi

apt-get install -y ./hd-community-waf.deb &> /dev/null
rm hd-community-waf.deb
echo -e "Haltdos Community WAF Installed"


curl -s -k -o hd-community-controller.deb https://binary.haltdos.com/community/waf/gui/hd-community-controller-x86_64.deb &> /dev/null
apt-get install -y ./hd-community-controller.deb &> /dev/null
rm hd-community-controller.deb
echo -e "Haltdos Community Controller Installed"


echo -e "Haltdos Community WAF Setup Done\n"
echo -e "Configure your WAF on https://$ip:9000\n"
export NEEDRESTART_SUSPEND=0