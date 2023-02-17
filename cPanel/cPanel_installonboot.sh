#!/bin/bash
set -e

# Commit:      fde6587e08ea95321ce010e52a9c1b8d02455a97
# Commit date: 2023-02-13 17:00:46 -0600
# Generated:   2023-02-17 11:00:28 -0600

# Add Logging to /var/log/stackscript.log for future troubleshooting
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

echo $(date +%Y%m%d%H%M%S) >> /tmp/cpdebug.log

# Linode's Weblish console will truncate lines unless you do this tput smam. This
# instructs the terminal to wrap your lines, which is especially important so that
# the WHM login URL that gets printed at the end can be copied.
tput smam

source /etc/os-release

is_os_and_version_id_prefix() {
  [[ $ID == $1 ]] && [[ $VERSION_ID =~ ^$2 ]]
}

is_almalinux8() {
  is_os_and_version_id_prefix almalinux 8
}

is_centos7() {
  is_os_and_version_id_prefix centos 7
}

is_cloudlinux7() {
  is_os_and_version_id_prefix cloudlinux 7
}

is_cloudlinux8() {
  is_os_and_version_id_prefix cloudlinux 8
}

is_rocky8() {
  is_os_and_version_id_prefix rocky 8
}

is_ubuntu20() {
  is_os_and_version_id_prefix ubuntu 20.04
}

is_supported_os() {
  is_almalinux8 || \
  is_centos7 || \
  is_cloudlinux7 || \
  is_cloudlinux8 || \
  is_rocky8 || \
  is_ubuntu20
}

has_yum() {
    which yum >/dev/null 2>&1
}

has_dnf() {
    which dnf >/dev/null 2>&1
}

has_apt() {
    which apt >/dev/null 2>&1
}

is_networkmanager_enabled() {
  systemctl is-enabled NetworkManager.service > /dev/null 2>&1
}

# cPanel & WHM is incompatible with NetworkManager
if is_networkmanager_enabled; then
  systemctl stop NetworkManager.service
  systemctl disable NetworkManager.service
  if has_dnf; then
    dnf -y remove NetworkManager
  elif has_yum; then
    yum -y remove NetworkManager
  fi
fi

hostnamectl set-hostname server.hostname.tld

cd /home && curl -so installer -L https://securedownloads.cpanel.net/latest

if is_supported_os; then
  if is_ubuntu20; then
    apt-get -o Acquire::ForceIPv4=true update -y
    DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" install grub-pc
    sh installer --skiplicensecheck --skip-cloudlinux
  else
    sh installer --skiplicensecheck
  fi
else
   echo "Your distribution is not supported by this StackScript."
   install -d -v -m 711 /var/cpanel
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
    URL=`whmlogin --nowait 2> /dev/null`
    WHMLOGIN_RETURN=$?

    if [ $WHMLOGIN_RETURN == 1 ]; then
        # whmlogin doesn't support --nowait.  Output a URL and hope it's accurate.
        echo "To log in to WHM as the root user, visit the following address in your web browser:"
        echo ""
        whmlogin
        echo ""
        echo "Thank you for using cPanel & WHM!"
    else
        if [ $WHMLOGIN_RETURN == 2 ]; then
            # whmlogin indicates that cpinit hasn't updated the IP/hostname yet.
            echo "To log in to WHM as the root user, run the command 'whmlogin' to get a web address for your browser."
            echo ""
            echo "Thank you for using cPanel & WHM!"
        else
            # whmlogin returned a valid URL to use.
            echo "To log in to WHM as the root user, visit the following address in your web browser:"
            echo ""
            echo "$URL"
            echo ""
            echo "Thank you for using cPanel & WHM!"
        fi
    fi
fi
END_OF_BASH_PROFILE

cat > /etc/motd.sh <<'END_OF_MOTD'
#!/bin/bash

source /etc/os-release

echo "
      ____                  _    ___    __        ___   _ __  __
  ___|  _ \ __ _ _ __   ___| |  ( _ )   \ \      / / | | |  \/  |
 / __| |_) / _. | ._ \ / _ \ |  / _ \/\  \ \ /\ / /| |_| | |\/| |
| (__|  __/ (_| | | | |  __/ | | (_>  <   \ V  V / |  _  | |  | |
 \___|_|   \__._|_| |_|\___|_|  \___/\/    \_/\_/  |_| |_|_|  |_|

"
echo "Welcome to cPanel & WHM `/usr/local/cpanel/cpanel -V`"
echo ""
echo "Running $PRETTY_NAME"
echo ""
echo "For our full cPanel & WHM documentation: https://go.cpanel.net/docs"
echo ""
echo "For information on how to quickly set up a website in cPanel & WHM: https://go.cpanel.net/buildasite"
echo "" # This new line makes output from bash_profiles easier to read
END_OF_MOTD
touch /var/cpanel/cpinit.done
