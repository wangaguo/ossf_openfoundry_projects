#!/bin/sh
OSSF_CHECKOUT="FIX ME"

RUBY=`which ruby`

SYNC_FILE="${OSSF_CHECKOUT}/sync.rb"
PID_FILE="${OSSF_CHECKOUT}/sync_cron.pid"
LOG_FILE="${OSSF_CHECKOUT}/rt_sync.log"

if [ -f $PID_FILE ]; then
        pid=`cat $PID_FILE`
        if [ -z "${pid}" ]; then
                rm $PID_FILE
        else
                ans=`ps aux ${pid} | grep ${pid}`
                if [ -z "${ans}" ]; then
                        rm $PID_FILE
                fi
        fi
fi
if [ ! -f $PID_FILE ]; then
        #. $RUBY_SOURCE
        $RUBY -I $OSSF_CHECKOUT $SYNC_FILE >> $LOG_FILE 2>&1 &
        echo $! > $PID_FILE
fi
