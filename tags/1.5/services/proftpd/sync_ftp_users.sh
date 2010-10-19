#!/bin/sh
PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
cd %%InstallDir%%;
mysql -u %%DB_USER%% -p%%DB_PASS%% -h %%DB_HOST%% < sync_ftp_users.sql >> ftp_sync.log 2>&1 
