#!/bin/sh -

if [ "$2" = "cvs server" ]; then
  exec /usr/bin/cvs server
fi
if [ "$2" = "svnserve -t" ]; then
  exec /usr/local/bin/svnserve -t
fi

echo "cvs and svn only. no shell access here."
sleep 5
exit 1
