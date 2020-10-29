#!/bin/bash
### linode
### Install OpenLiteSpeed and WordPress
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Setup/wpimgsetup.sh )
### Regenerate password for Web Admin, Database, setup Welcome Message
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Cloud-init/per-instance.sh )
### Clean up ls tmp folder
sudo rm -rf /tmp/lshttpd/*