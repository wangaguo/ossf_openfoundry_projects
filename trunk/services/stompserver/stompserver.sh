#!/bin/sh
. %%InstallDir%%/ruby/ruby_settings.sh # TODO: ruby path
stompserver -C %%InstallDir%%/stompserver.conf >> %%InstallDir%%/stompserver.log 2>&1 &
echo $! > stompserver.pid
