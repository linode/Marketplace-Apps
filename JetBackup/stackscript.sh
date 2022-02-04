#!/bin/bash
# JetBackup StackScript UDF Variables
# <UDF name="CONTROLPANEL" Label="Choose a Control Panel to use with JetBackup 5. cPanel/WHM or Linux (No Control Panel)" default="cPanel/WHM" oneof="cPanel/WHM,Linux" />
# <UDF name="RELEASETIER" Label="Choose a JetBackup Release Tier." default="stable" oneof="stable,beta,edge" />
#
# The next line makes the Official cPanel StackScript available if cPanel/WHM is selected as the control panel. Do not remove this line.
# source <ssinclude StackScriptID="595742">
#
# Log File Paths:
# StackScript Log: /var/log/stackscript.log
# cPanel/WHM installation: /var/log/stackscript-595742.log
# Debugging: /var/log/stackscript-debug.log
#
exec 1> >(tee -a "/var/log/stackscript.log") 2>/var/log/stackscript-debug.log
echo "PID: $$"
CONTROLPANEL=${CONTROLPANEL}
RELEASE=${RELEASETIER}
JBDIR="/usr/local/jetapps/etc/jetbackup5"

if [[ -z ${CONTROLPANEL} ]]; then
echo "Error: No panel selected. Please select a panel to deploy JetBackup."
exit 1
elif [[ -d ${JBDIR} ]]; then
echo "Error: JetBackup already installed. Aborting StackScript."
exit 0
fi

echo "Installing JetApps Repository"
rpm --import http://repo.jetlicense.com/centOS/RPM-GPG-KEY-JETAPPS
yum -y -q install http://repo.jetlicense.com/centOS/jetapps-repo-latest.rpm
yum -y -q install jetapps --disablerepo=* --enablerepo=jetapps
echo "JetApps Repository Successfully Installed."

cpanelinstall() {

echo "Running cPanel/WHM Marketplace StackScript. You can track the progress of cPanel/WHM with: tail -f /var/log/stackscript-595742.log "
(source /root/ssinclude-595742 >>/var/log/stackscript-595742.log 2>&1)

}

# JETBACKUP 5 FOR LINUX - STANDALONE INSTALLATION

if [ "${CONTROLPANEL}" = "Linux" ]; then
echo "Installing JetBackup 5."
package='jetbackup5-linux'
jetapps --install $package $RELEASE
jbhostname=$(hostname)
jbhostname="https://${jbhostname}:3035"
echo "Adding a Firewall rule to open port 3035. Port 3035 must be open for access to the JetBackup 5 Linux UI."
firewall-cmd --permanent --add-port=3035/tcp
firewall-cmd --reload
echo "To go to JetBackup and Accept the User Agreement, go to ${jbhostname} and enter your root login credentials."
echo "To generate a one-time JetBackup 5 login URL after installation and acceptance of the EULA type  the following command in the terminal:"
echo "jb5login"
fi

# JETBACKUP 5 FOR CPANEL/WHM INSTALLATION

if [ "${CONTROLPANEL}" = "cPanel/WHM" ]; then

package='jetbackup5-cpanel'
cpanelinstall
sleep 2
echo "Installing JetBackup 5."
jetapps --install $package $RELEASE
echo "To log in to cPanel/WHM as root user, please enter the following command to generate a one-time login token:"
echo ""
echo "whmlogin"
fi

echo "Review the JetBackup 5 Getting Started Guide at https://docs.jetbackup.com/v5.1/adminpanel/gettingStarted.html"
installVersion="$(jetbackup5 --version | cut -d ' ' -f 1,3,4 | sed "2 d")"
echo "${installVersion} Successfully Installed!"
rm /root/ssinclude-595742
rm /root/StackScript
exit 0