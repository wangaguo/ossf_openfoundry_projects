#!/bin/sh
umask 007
PROJECT_ID=$1
PROJECT_NAME=$2
PROJECT_UPLOAD_PATH=/usr/local/webhosting/upload

cd tmp
tar zxvf ../webhosting.tar.gz
find . -depth 3 -type d | awk '{ print "FOO=`basename "$1"`\nmkdir -p /usr/local/webhosting/upload/${FOO}\ncp -PR "$1" /usr/local/webhosting/upload/${FOO}/www";}'
rm -R *
fi
