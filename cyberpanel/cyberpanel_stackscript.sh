#!/bin/bash
### linode
## Enable logging
exec > >(tee /dev/ttyS0 /var/log/stackscript.log) 2>&1

### Install cyberpanel
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Setup/cybersetup.sh )

### Regenerate password for Web Admin, Database, setup Welcome Message
bash <( curl -sk https://raw.githubusercontent.com/litespeedtech/ls-cloud-image/master/Cloud-init/per-instance.sh )

### Clean up ls tmp folder
sudo rm -rf /tmp/lshttpd/*