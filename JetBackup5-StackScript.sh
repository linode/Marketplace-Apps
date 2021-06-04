#!/bin/bash
set -ex
# JetBackup UDF Variables
# <UDF name="CONTROL_PANEL" Label="Would you like to install cPanel/WHM with JetBackup 5, or install JetBackup 5 for Linux. (No Control Panel)." default="cPanel" oneof="cPanel,Linux" />
# <UDF name="RELEASE_TIER" Label="Select your JetBackup Release Tier." default="stable" example="" oneof="stable,beta,edge" />
# The next line makes the cPanel StackScript available for the cpanelinstall function on deployment of the linode. Do not remove this line.
# source <ssinclude StackScriptID="595742">
#
# Log File Paths:
# Primary Log for this script: /var/log/stackscript.log
# cPanel/WHM's installation: /var/log/stackscript-595742.log 
# Debugging: /var/log/stackscript-debug.log
#
exec 1> >(tee -a "/var/log/stackscript.log") 2>/var/log/stackscript-debug.log

### VARIABLES ###
CONTROL_PANEL="${CONTROL_PANEL}"
RELEASE_TIER="${RELEASE_TIER}"
installVersion="none"
jbhostname="none"
JB_DIR="/usr/local/jetapps/etc/jetbackup5"
echo "PID: $$"

if [[ -z ${CONTROL_PANEL} ]]; then 
echo "Error: No panel selected. Please select a panel to deploy JetBackup."
exit 1 
elif [[ -d ${JB_DIR} ]]; then
echo "Error: JetBackup already installed. Aborting StackScript."
exit 1 
fi

## Check yum processes to prevent yum lock queue. This is necessary because cPanel takes the yum lock for 5-10+ minutes and is better able to hold the lock.
check_yum_processes() {

  numProcess=$(ps -ef | grep 'yum' | grep -v 'grep' | wc | awk '{ gsub(/^[ \t]+|[ \t]+$/, ""); print $1}')

  while [ $numProcess -ge 1 ]; do
    echo "Waiting for yum lock to clear. There are ${numProcess} tasks running. This could take a while. Please do not exit or kill the script while it's running."

    sleep 5
    numProcess=$(ps -ef | grep 'yum' | grep -v 'grep' | wc | awk '{ gsub(/^[ \t]+|[ \t]+$/, ""); print $1}')
    if [ $numProcess -eq 0 ]; then
      break
    fi
  done

}



cpanelinstall() {

  echo "Running cPanel/WHM Marketplace StackScript."
  echo "We will wait for cPanel/WHM installation to complete to prevent conflicts. JetBackup will be installed after cPanel/WHM has completed."
  echo "This could take a while. Please do not exit or kill the script while it's running."
  echo "You can track the progress of cPanel/WHM with: tail -f /var/log/stackscript-595742.log "
  source /root/ssinclude-595742 >>/var/log/stackscript-595742.log 2>&1

}


install_jetbackup() {
  echo "Verifying yum is not in use by other processes..."
  rpm --import http://repo.jetlicense.com/centOS/RPM-GPG-KEY-JETAPPS
  check_yum_processes
  echo "Installing JetApps Repository"
  yum install http://repo.jetlicense.com/centOS/jetapps-repo-latest.rpm -y -q -e 0 && yum install jetapps --disablerepo=* --enablerepo=jetapps -y
  echo "Installing JetApps Package"
  yum install jetapps --disablerepo=* --enablerepo=jetapps -y -q -e 0
  echo "Installing JetBackup 5 via JetApps repository"
  jetapps --install ${CONTROL_PANEL} ${RELEASE_TIER}

}

notifySuccessVersion() {

  installVersion="$(jetbackup5 --version | cut -d ' ' -f 1,3,4 | sed "2 d")"
  echo "${installVersion} Successfully Installed!"

}

#################################
#### MAIN SCRIPT STARTS HERE ####
#################################
## We verify if a JetBackup installation already exists because cPanel/WHM will auto-install JetBackup when an active license exists on the cPanel store.
## If JB5 path doesn't exist, JetBackup 5 can be installed.
## If JetBackup is already installed, the script will abort the installation.

if [[ ! -d "${JB_DIR}" ]]; then

  echo "JetBackup 5 Installation Started."

  if [[ "${CONTROL_PANEL}" = "Linux" ]]; then
    CONTROL_PANEL="jetbackup5-linux"
    install_jetbackup
    jbhostname=$(hostname)
    jbhostname="https://${jbhostname}:3035"
    echo "Adding a Firewall rule to open port 3035 using command "firewall-cmd --permanent --add-port=3035/tcp""
    echo "Port 3035 must be open for access to the JetBackup 5 Linux UI."
    firewall-cmd --permanent --add-port=3035/tcp
    firewall-cmd --reload
    echo ""
    echo "After installing JetBackup, please ensure your firewall and/or SELinux isn't blocking access on required ports."
    echo ""
    echo "You must accept the End User License Agreement to use JetBackup 5.  Certain functions will be disabled until you accept the user Agreement in the UI."
    echo "To go to JetBackup and Accept the User Agreement, go to ${jbhostname} and enter your root login credentials."
    echo ""
    echo "To generate a one-time JetBackup 5 login URL after installation and acceptance of the EULA type  the following command in the terminal:" 
    echo ""
    echo "jb5login"
    echo ""
  fi

  if [[ "${CONTROL_PANEL}" = "cPanel" ]]; then

    CONTROL_PANEL="jetbackup-cpanel"
    cpanelinstall
    sleep 5
    install_jetbackup
    echo ""
    echo "cPanel recommends disabling SELinux post-installation. Review cPanel Documentaition for SELinux: https://docs.cpanel.net/installation-guide/system-requirements-centos/#disable-selinux"
    echo "Please ensure you configure your server Firewall, SELinux, etc to ensure proper function of cPanel/WHM and JetBackup."
    echo "For information on how to access cPanel/WHM, please visit https://docs.cpanel.net/knowledge-base/accounts/how-to-log-in-to-your-server-or-account/#how-to-access-whm "
    echo ""
    echo "You must accept the End User License Agreement to use JetBackup 5. Certain functions will be disabled until you accept the user Agreement in the UI."
    echo "Go to WHM > Plugins > JetBackup to confirm you have read and accept the EULA."
    echo "To log in to cPanel/WHM as root user, please enter the following command to generate a one-time login token:"
    echo ""
    echo "whmlogin"
    echo ""

  fi

  echo ""
  echo "Review the JetBackup 5 Getting Started Guide at https://docs.jetbackup.com/v5.1/adminpanel/gettingStarted.html"
  notifySuccessVersion
  echo "StackScript Deployment Completed."

fi

# Clean StackScripts.
rm /root/ssinclude*
rm /root/StackScript
exit 0
