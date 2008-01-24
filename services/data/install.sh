#!/bin/sh
db=$1      #openfoundry_development
db_user=$2 #openfoundry
db_pass=$3

wait_mysql()
{
        for i in 1 2 3 4 5 6 7 8 9 10
        do
                /usr/local/etc/rc.d/mysql-server status && return 0
                echo 'wait 1 sec'
                sleep 1
        done
        return 1
}


pkg_add -r mysql50-server
echo 'mysql_enable="YES"' >> /etc/rc.conf
/usr/local/etc/rc.d/mysql-server start
if wait_mysql; then
	mysqladmin create ${db}
	mysql -u root -e "grant all on ${db}.* to '${db_user}'@'%' identified by '${db_pass}'"
        echo "Done."
else
        echo "MySQL did not start!"
fi


