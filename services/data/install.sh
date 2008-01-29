#!/bin/sh
DB_PREFIX=$1 # of => of_development
DB_USER=$2   # openfoundry
DB_PASS=$3

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


env PACKAGEROOT='ftp://ftp.tw.freebsd.org' pkg_add -r mysql50-server
echo 'mysql_enable="YES"' >> /etc/rc.conf
echo 'mysql_args="--default-character-set=utf8"' >> /etc/rc.conf
/usr/local/etc/rc.d/mysql-server start
if wait_mysql; then
	mysqladmin create "${DB_PREFIX}_development" 
	mysqladmin create "${DB_PREFIX}_test" 
	mysqladmin create "${DB_PREFIX}_production" 
	mysql -u root -e "grant all on ${DB_PREFIX}_development.* to '${DB_USER}'@'%' identified by '${DB_PASS}'"
	mysql -u root -e "grant all on ${DB_PREFIX}_test.* to '${DB_USER}'@'%' identified by '${DB_PASS}'"
	mysql -u root -e "grant all on ${DB_PREFIX}_production.* to '${DB_USER}'@'%' identified by '${DB_PASS}'"
        echo "Done."
else
        echo "MySQL did not start!"
fi


