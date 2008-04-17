#!/bin/sh
PATH=${PATH}:/usr/local/bin
mysql -uroot -B -s -e "SELECT unixname,redirecturl FROM of_development.projects WHERE redirecturl IS NOT NULL" > /usr/local/webhosting/conf/redirect.txt.new
mv /usr/local/webhosting/conf/redirect.txt.new /usr/local/webhosting/conf/redirect.txt
