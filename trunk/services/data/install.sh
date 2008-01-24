#!/bin/sh
db=$1      #openfoundry_development
db_user=$2 #openfoundry
db_pass=$3

pkg_add -r mysql50-server
echo 'mysql_enable="YES"' >> /etc/rc.conf
/usr/local/etc/rc.d/mysql-server start
mysqladmin create ${db}
mysql -u root -e "grant all on ${db}.* to '${user}'@'%' identified by '${pass}'"
