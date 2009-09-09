#!/bin/sh
mysql -uopenfoundry -possfossf -h192.168.0.10 -B -s -e "SELECT id+10000000,name FROM of_development.projects WHERE status=2" | awk '{print "./init_upload_dir.sh "$0}'|sh
