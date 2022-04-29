#!/bin/bash
set -e

# Add Logging to /var/log/stackscript.log for future troubleshooting
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

echo $(date +%Y%m%d%H%M%S) >> /tmp/cpdebug.log
# Linode CentOS has NetworkManager, which is incompatible with cPanel & WHM
if [ -f /etc/redhat-release ]; then
  systemctl stop NetworkManager.service
  systemctl disable NetworkManager.service
  yum -y remove NetworkManager || dnf -y remove NetworkManager
fi
# Linode's Weblish console will truncate lines unless you do this tput smam. This
# instructs the terminal to wrap your lines, which is especially important so that
# the WHM login URL that gets printed at the end can be copied.
tput smam
cd /home && curl -so installer -L https://securedownloads.cpanel.net/latest
source /etc/os-release
if [ "$ID" = ubuntu ]; then
  apt-get -o Acquire::ForceIPv4=true update -y
  DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc
  sh installer --skiplicensecheck --skip-cloudlinux
elif [ "$ID" = centos ]; then
  sh installer --skiplicensecheck
else
   echo "Your distribution is not supported by this StackScript."
   touch /var/cpanel/cpinit.failed
fi
rm -f /etc/cpupdate.conf
cat > /root/.bash_profile <<'END_OF_BASH_PROFILE'
# .bash_profile
# Get the aliases and functions
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
# User specific environment and startup programs
PATH=$PATH:$HOME/bin
export PATH
bash /etc/motd.sh
if [ -t 0 ]; then
    echo "To log in to cPanel, please visit the following address in your web browser:"
    echo ""
    whmlogin
    echo ""
    echo "Thank you for using cPanel & WHM!"
fi
END_OF_BASH_PROFILE
cat > /etc/motd.sh <<'END_OF_MOTD'
#!/bin/bash
echo "
      ____                  _    ___    __        ___   _ __  __
  ___|  _ \ __ _ _ __   ___| |  ( _ )   \ \      / / | | |  \/  |
 / __| |_) / _. | ._ \ / _ \ |  / _ \/\  \ \ /\ / /| |_| | |\/| |
| (__|  __/ (_| | | | |  __/ | | (_>  <   \ V  V / |  _  | |  | |
 \___|_|   \__._|_| |_|\___|_|  \___/\/    \_/\_/  |_| |_|_|  |_|
"
echo "Welcome to cPanel & WHM `/usr/local/cpanel/cpanel -V`"
echo ""
echo "Running `cat /etc/redhat-release`"
echo ""
echo "For our full cPanel & WHM documentation: https://go.cpanel.net/docs"
echo ""
echo "For information on how to quickly set up a website in cPanel & WHM: https://go.cpanel.net/buildasite"
echo "" # This new line makes output from bash_profiles easier to read
END_OF_MOTD
touch /var/cpanel/cpinit.done

