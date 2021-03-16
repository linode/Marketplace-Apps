#!/bin/bash
set -ex
## Logs: cat /var/log/stackscript.log
## 
# <UDF name="PANEL" label="Would you like to install cPanel/WHM with JetBackup 5, or install JetBackup 5 for Linux. (No Control Panel)." default="cPanel" example="" oneof="cPanel,Linux" />
# <UDF name="TIER" label="Select your JetBackup Release Tier. Stable is recommended for most installations." default="stable" example="" oneof="stable,beta,edge" />
# The next line makes the cPanel StackScript available for the cpanelinstall function on deployment of the linode. Do not remove this line.
# source <ssinclude StackScriptID="595742">
#
# Log File Paths:
# Primary Log for this script: /var/log/stackscript.log
# cPanel/WHM's installation: /var/log/stackscript-595742.log
# Debugging: /var/log/stackscript-debug.log
#

PanelSelection="${PANEL}"
RELEASE="undefined"
UDF_TIER="${TIER}"
JB_DIR="/usr/local/jetapps/etc/jetbackup5"

exec >/var/log/stackscript.log 2>/var/log/stackscript-debug.log

# This function checks what Panel and Release Tier were selected for Linode StackScript Deployment. The cPanel StackScript will be ran as a separate process with "disown" to prevent unexpected termination the StackScript.

panel_selection() {

    case $PanelSelection in
    cPanel)
        echo "$PanelSelection"
        echo "pid is $$"
        RELEASE="jetbackup-cpanel"
        cpanelinstall
        echo "cPanel/WHM Installation Completed!"
        # Sleep 10: cPanel takes the yum lock soon after installation, but not immediately.
        sleep 10
        echo "Verifying yum is not in use by other processes..."
        check_yum_processes
        ;;
    Linux)
        RELEASE="jetbackup5-linux"
        echo "$PanelSelection"
        echo "pid is $$"
        ;;
    *)
        echo "ABORTED: No panel or JetBackup release tier selected. Please install JetBackup manually: https://docs.jetbackup.com/"
        ;;
    esac

}

cpanelinstall() {
    ## This will install cPanel/WHM and log all output of the cPanel/WHM Marketplace Script to the path indicated.

    echo "Running cPanel/WHM Marketplace Script."
    echo "We will wait for cPanel/WHM installation to complete to prevent conflicts. JetBackup will be installed after cPanel/WHM has completed."
    echo "This could take a while. Please do not exit or kill the script while it's running."
    source /root/ssinclude-595742 >>/var/log/stackscript-595742.log 2>&1
    
}

## Check yum processes to prevent yum lock queue. This is necessary because cPanel takes the yum lock for 5-10+ minutes and is better able to keep the lock.
# Sleep 15: cPanel's update tasks include multiple packages that take a while to download and install.
check_yum_processes() {

    numProcess=$(ps -ef | grep 'yum' | grep -v 'grep' | wc | awk '{print $1}')

    while [[ $numProcess -ge 1 ]]; do
        echo "Waiting for yum lock to clear. There are '$numProcess' tasks running. This could take a while. Please do not exit or kill the script while it's running."
        sleep 15
        numProcess=$(ps -ef | grep 'yum' | grep -v 'grep' | wc | awk '{print $1}')
        continue
        if [[ $numProcess -eq 0 ]]; then
            break
        fi
    done

}


## This installs the JetApps Repo.

install_jetapps_repo() {
    echo "Verifying yum is not in use by other processes..."
    check_yum_processes
    echo "Installing JetApps Repository..."
    yum install http://repo.jetlicense.com/centOS/jetapps-repo-latest.rpm -y -q -e 0
    echo "Installing JetApps Package..."
    yum install jetapps --disablerepo=* --enablerepo=jetapps -y -q -e 0

}

## This installs JetBackup based on release and tier.

install_jetbackup() {
    echo "Verifying yum is not in use by other processes..."
    check_yum_processes
    echo "Installing JetBackup 5 via JetApps repository..."
    jetapps --install ${RELEASE} ${UDF_TIER}
    if [ ${RELEASE} = "jetbackup5-linux" ]; then
        echo ""
        echo "IMPORTANT: Firewalld and SELinux are ** enabled ** by default in CentOS and can interfere with JetBackup."
        echo "Before you start configuring JetBackup, please ensure that your firewall allows access on port 3035."
        echo ""
        echo "You can generate a login URL after installation by typing "jb5login" "
    else
        echo ""

    fi
}

#################################
#### MAIN SCRIPT STARTS HERE ####
#################################
## First, we verify if a JetBackup installation already exists. cPanel/WHM will auto-install JetBackup when an active license exists on the cPanel store.
## If JB5 path doesn't exist, JetBackup 5 can be installed.
## If JetBackup is already installed, the script will abort the installation.

echo "Starting JetBackup 5 StackScript..."
panel_selection
echo "Checking if JetBackup is already installed..."

if [ ! -d "${JB_DIR}" ]; then

    echo "JetBackup 5 Installation Started."
    install_jetapps_repo
    install_jetbackup
    echo "Verifying JetBackup version..."
    INSTALLED_VERSION="$(jetbackup5 --version | cut -d ' ' -f 1,3,4 | sed "2 d")"
    echo ""
    echo "${INSTALLED_VERSION} Installed!"
    echo ""
    echo "NEXT STEPS:"
    echo "Please verify your server configuration, firewall, etc are set up and configured properly. You may encounter issues using JetBackup if these are not configured properly."
    echo ""
    echo "Review the JetBackup 5 "Getting Started" Guide at https://docs.jetbackup.com/v5.1/adminpanel/gettingStarted.html"
    echo ""
    echo "StackScript Deployment Completed."

elif [ -d "${JB_DIR}" ]; then
    echo "Aborted: JetBackup 5 Installation already exists on the server. Please contact support@jetapps.com for questions or review the documentation: https://docs.jetbackup.com/v5.1/adminpanel/index.html "
fi

# Clean StackScripts. 
rm /root/ssinclude*
rm /root/StackScript
exit 0
