#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail
set -o xtrace

# <UDF name="wirespeed_admin_email" Label="Admin Email" default="" example="it@example.com" />
# <UDF name="wirespeed_admin_password" Label="Admin Password" default="" example="Password" />
# <UDF name="wirespeed_http_host" Label="DNS Name" default="" example="vpn.example.com" />
# <UDF name="wirespeed_data_dir" Label="Data Directory" default="/wirespeed" example="/wirespeed" />

## REQUIRED IN EVERY MARKETPLACE SUBMISSION
exec 1> >(tee -a "/var/log/stackscript.log") 2>&1
export DEBIAN_FRONTEND="noninteractive"
apt-get \
  -o 'Acquire::ForceIPv4=true' \
  --yes \
  update

apt-get \
  -o 'DPkg::options::=--force-confdef' \
  -o 'DPkg::options::=--force-confold' \
  --yes \
  install grub-pc

apt-get \
  -o Acquire::ForceIPv4=true \
  --yes \
  update
# # END OF REQUIRED CODE FOR MARKETPLACE SUBMISSION

# Handle the arguments.
WIRESPEED_ADMIN_EMAIL="$(echo -e "${WIRESPEED_ADMIN_EMAIL}" | tr --delete '[:space:]')"
WIRESPEED_HTTP_HOST="$(echo -e "${WIRESPEED_HTTP_HOST}" | tr --delete '[:space:]')"
WIRESPEED_HTTP_HOST="${WIRESPEED_HTTP_HOST//\//}"
WIRESPEED_HTTP_HOST="${WIRESPEED_HTTP_HOST//https:/}"
WIRESPEED_HTTP_HOST="${WIRESPEED_HTTP_HOST//http:/}"

if [[ -z "${WIRESPEED_ADMIN_EMAIL}" ]]; then
  echo "Missing required parameter: admin email"
  exit 101
fi

if [[ -z "${WIRESPEED_HTTP_HOST}" ]]; then
  echo "Missing required parameter: http host"
  exit 102
fi

if [[ -z "${WIRESPEED_DATA_DIR}" ]]; then
  WIRESPEED_DATA_DIR="/wirespeed"
fi

# Set hostname
IP="$(hostname --all-ip-addresses | awk '{ print $1 }')"
hostnamectl set-hostname "${WIRESPEED_HTTP_HOST}"
echo "${IP} ${WIRESPEED_HTTP_HOST}" >>/etc/hosts

wget https://bunker.services/wirespeed-installer.sh
chmod +x wirespeed-installer.sh
./wirespeed-installer.sh \
  "${WIRESPEED_HTTP_HOST}" \
  "${WIRESPEED_DATA_DIR}" \
  "${WIRESPEED_ADMIN_EMAIL}" \
  "${WIRESPEED_ADMIN_PASSWORD}" \
  --non-interactive

# Force IPv4 and noninteractive upgrade after script runs to prevent breaking nf_conntrack for UFW
echo 'Acquire::ForceIPv4 "true";' >/etc/apt/apt.conf.d/99force-ipv4
apt-get upgrade --yes

for file in /root/StackScript /root/ssinclude* /root/wirespeed-installer.sh; do
  rm "${file}"
done

echo 'WireSpeed Installation complete!'