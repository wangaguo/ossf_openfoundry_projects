#!/bin/sh -

case $2 in
	cvs*) exec /usr/bin/cvs server ;;
	svnserve*) exec /usr/local/bin/svnserve -t ;;
	*) echo "cvs and svn only. no shell access here."; sleep 5; exit 1 ;; 
esac
