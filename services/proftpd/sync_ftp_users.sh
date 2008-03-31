#!/bin/sh
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
cd ~root;
mysql -uroot < sync_ftp_users.sql
