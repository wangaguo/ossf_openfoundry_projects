#!/bin/sh
cd /root/CodeSnippets
SYNC_SECRET="FIX ME"
SYNC_HOST="FIX ME"
SYNC_SCRIPT=group.pl
DUMP_LINK="http://${SYNC_HOST}/openfoundry/foundry_sync?secret=${SYNC_SECRET}&module=rt"

JSON_DUMP=b.json
RESULT_LOG=group_result.txt
CHECK_LOG=group_result2.txt

#utils...
PERL=`which perl`
DATE=/bin/date
FETCH=`which fetch`
GREP=/usr/bin/grep

echo "#####################" >> ${RESULT_LOG}
$DATE >> ${RESULT_LOG}
echo "#####################" >> ${RESULT_LOG}
  
if $FETCH -o $JSON_DUMP ${DUMP_LINK} ; then
  
  $PERL $SYNC_SCRIPT > ${RESULT_LOG}
  $PERL $SYNC_SCRIPT > ${CHECK_LOG}
  
  if $GREP 'should' $CHECK_LOG ; then
      echo "bad"
  else
      echo "good"
  fi
  
else
    echo "fetch failed!!!!!!!!!!!!!!!!!!!!" >> ${RESULE_LOG}
fi
