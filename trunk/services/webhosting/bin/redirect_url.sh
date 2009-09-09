#!/bin/sh
PATH=${PATH}:/usr/local/bin
mysql -uopenfoundry -possfossf -h192.168.0.10 -B -s -e "SELECT name,redirecturl FROM of_development.projects WHERE redirecturl != '' AND redirecturl IS NOT NULL" > /usr/local/webhosting/conf/redirect.txt.new
mv /usr/local/webhosting/conf/redirect.txt.new /usr/local/webhosting/conf/redirect.txt
