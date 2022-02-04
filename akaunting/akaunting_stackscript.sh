#!/bin/bash

# <UDF name="company_name" Label="Company Name" default="My Company" />
# <UDF name="company_email" Label="Company Email" default="my@company.com" />
# <UDF name="admin_email" Label="Admin Email" default="my@company.com" />
# <UDF name="admin_password" Label="Admin Password" default="123654" />

# <UDF name="db_name" Label="MySQL Database Name" default="akaunting" />
# <UDF name="db_password" Label="MySQL root Password" default="123654" />
# <UDF name="dbuser" Label="MySQL Username" default="akaunting" />
# <UDF name="dbuser_password" Label="MySQL User Password" default="123654" />

# Add Logging to /var/log/stackscript.log for future troubleshooting
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

source <ssinclude StackScriptID=921753>

###########################################################
# Stackscript cleanup
###########################################################
rm /root/StackScript
rm /root/ssinclude*
echo "Installation complete!"