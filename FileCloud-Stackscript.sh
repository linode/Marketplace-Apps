#!/bin/bash 
##  

# <UDF name="admin_password" Label="FileCloud Admin Password" />

# Download FileCloud silent installer script
curl -L -o /tmp/fc-silent.sh https://patch.codelathe.com/tonidocloud/live/installer/fc-silent.sh

# Remove lines to avoid upgrade of packages on Debian/Ubuntu
sed -i -e 's/apt-get upgrade/apt-get update/g' /tmp/fc-silent.sh

# Enable execute permission for the script
chmod +x /tmp/fc-silent.sh

# Execute the installer script
bash /tmp/fc-silent.sh

# Set the Admin Password in FileCloud config file
sed -i -e 's/\(.*TONIDOCLOUD_ADMIN_PASSWORD", "\).*\(");\)/\1'"$ADMIN_PASSWORD"'\2/g' /var/www/html/config/cloudconfig.php