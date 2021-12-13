#!/usr/bin/env bash

ZIP_FILE="https://github.com/ant-media/Ant-Media-Server/releases/download/ams-v2.4.1/ant-media-server-community-2.4.1.zip"
INSTALL_SCRIPT="https://raw.githubusercontent.com/ant-media/Scripts/master/install_ant-media-server.sh"

wget -q --no-check-certificate $ZIP_FILE -O /tmp/antmedia.zip && wget -q --no-check-certificate $INSTALL_SCRIPT -P /tmp/

if [ $? == "0" ]; then
  bash /tmp/install_ant-media-server.sh -i /tmp/antmedia.zip
else
  logger "There is a problem in installing the ant media server. Please send the log of this console to contact@antmedia.io"
  exit 1
fi
   
