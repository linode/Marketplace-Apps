#!bin/bash

# <UDF name="license_key" label="License Key" />

wget -qO- https://get.bitninja.io/install.sh | /bin/bash -s - --license_key="$license_key"