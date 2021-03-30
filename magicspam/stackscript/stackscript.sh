#!/bin/bash
# <UDF name="web_panel" Label="The web panel to install alongside with MagicSpam. Please make sure to choose the appropriate Image for the selected web panel. For more information, please refer to the MagicSpam App Information Sidebar." oneof="cPanel,Plesk">
# <UDF name="ms_license_key" Label="The MagicSpam license key. Please make sure to use the appropriate license key for the selected web panel. For more information, please refer to the MagicSpam App information sidebar.">
# <UDF name="hostname" label="The server hostname.">

# source the stackscript for the selected web panel
if [ "$WEB_PANEL" == "cPanel" ]; then
    # redirect ALL output to the stackscript log for future troubleshooting
    exec 1> >(tee -a "/var/log/stackscript.log") 2>&1

    # cPanel Marketplace App install
    source <ssinclude StackScriptID=595742>

    # set the hostname to replicate Plesk stackscript for consistent behavior
    IPADDR=$(/sbin/ifconfig eth0 | awk '/inet / { print $2 }' | sed 's/addr://')
    echo $HOSTNAME > /etc/hostname
    hostname -F /etc/hostname
    echo $IPADDR $HOSTNAME >> /etc/hosts
elif [ "$WEB_PANEL" == "Plesk" ]; then
    # Plesk Marketplace App install
    # NOTE: do not redirect output to the stacksript log in this stackscript to
    #       avoid duplicate log lines as the Plesk stackscript already redirects
    source <ssinclude StackScriptID=593835>
else
    echo "Invalid web panel option detected. Aborting..."
    exit 1
fi

# install MagicSpam via the installer script
wget https://www.magicspam.com/download/magicspam-installer.sh -O /root/magicspam-installer
chmod +x /root/magicspam-installer
/root/magicspam-installer -l "$MS_LICENSE_KEY"
