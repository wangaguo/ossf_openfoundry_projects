#!/bin/sh
umask 007
PROJECT_ID=$1
PROJECT_NAME=$2
PROJECT_UPLOAD_PATH=/usr/local/webhosting/upload

cd $PROJECT_UPLOAD_PATH
if [ -d $PROJECT_NAME ] ; then
  echo $PROJECT_NAME
else
  mkdir $PROJECT_NAME
  setfacl -d -m u::rwx,g::rwx,o::---,u:www:r-x,u:openfoundry:r-x $PROJECT_NAME
  setfacl -m u::rwx,g::rwx,o::---,u:www:r-x,u:openfoundry:r-x $PROJECT_NAME
  mkdir $PROJECT_NAME/upload
  chmod 750 $PROJECT_NAME
  chmod 770 $PROJECT_NAME/upload
  chgrp -R $PROJECT_ID $PROJECT_NAME
  cat << 'FOO' > $PROJECT_NAME/upload/.ftpaccess
  <Limit MKD>
    DenyAll
  </Limit>
  PathAllowFilter ^[A-Za-z0-9._-]+$
FOO
  chmod 640 $PROJECT_NAME/upload/.ftpaccess
fi
