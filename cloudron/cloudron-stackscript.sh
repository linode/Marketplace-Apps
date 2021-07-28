#!/bin/bash

set -eu

wget https://cloudron.io/cloudron-setup
chmod +x cloudron-setup
./cloudron-setup --provider linode-mp

