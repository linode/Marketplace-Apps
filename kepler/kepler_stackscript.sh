#!/usr/bin/env bash

### Installs WordPress and creates first site.

## WordPress Settings
# <UDF name="site_title" label="Website Title" default="My WordPress Site" example="My Blog">
# <UDF name="soa_email_address" label="E-Mail Address" example="Your email address">
# <UDF name="wp_admin" label="Admin Username" example="Username for your WordPress admin panel">
# <UDF name="wp_password" label="Admin Password" example="an0th3r_s3cure_p4ssw0rd">
# <UDF name="db_root_password" label="MySQL root Password" example="an0th3r_s3cure_p4ssw0rd">
# <UDF name="db_password" label="WordPress Database Password" example="an0th3r_s3cure_p4ssw0rd">

## Linode/SSH Security Settings
#<UDF name="username" label="The limited sudo user to be created for the Linode" default="">
#<UDF name="password" label="The password for the limited sudo user" example="an0th3r_s3cure_p4ssw0rd" default="">
#<UDF name="pubkey_password" label="The SSH Public Key that will be used to access the Linode" default="">
#<UDF name="pwless_sudo" label="Enable passwordless sudo access for the limited user?" oneOf="Yes,No" default="No">
#<UDF name="disable_root" label="Disable root access over SSH?" oneOf="Yes,No" default="No">
#<UDF name="auto_updates" label="Configure automatic security updates?" oneOf="Yes,No" default="No">
#<UDF name="fail2ban" label="Use fail2ban to prevent automated intrusion attempts?" oneOf="Yes,No" default="No">

## Domain Settings
#<UDF name="token_password" label="Your Linode API token. This is needed to create your DNS records" default="">
#<UDF name="subdomain" label="Subdomain" example="The subdomain for your server: www" default="">
#<UDF name="domain" label="Domain" example="The domain for your Linode: example.com" default="">
#<UDF name="mx" label="Do you need an MX record for this domain? (Yes if sending mail from this Linode)" oneOf="Yes,No" default="No">
#<UDF name="spf" label="Do you need an SPF record for this domain? (Yes if sending mail from this Linode)" oneOf="Yes,No" default="No">
#<UDF name="ssl" label="Would you like to use a free Let's Encrypt SSL certificate? (Domain required)" oneOf="Yes,No" default="No">

## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

## Import the Bash StackScript Library
source <ssinclude StackScriptID=1>

## Import the DNS/API Functions Library
source <ssinclude StackScriptID=632759>

## Import the OCA Helper Functions
source <ssinclude StackScriptID=401712>

## Run initial configuration tasks (DNS/SSH stuff, etc...)
source <ssinclude StackScriptID=666912>

# Wordpress install
source <ssinclude StackScriptID=401697>

# Install Kepler theme
wget https://storage.googleapis.com/kepler-download/kepler-theme.zip?ignoreCache=1 -O kepler-theme.zip
wp theme install --allow-root kepler-theme.zip --activate

# Install Kepler builder plugin
wget https://storage.googleapis.com/kepler-download/kepler-builder.zip -O kepler-builder.zip
wp plugin install --allow-root kepler-builder.zip --activate

# Cleanup
stackscript_cleanup