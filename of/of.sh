#!/bin/sh
cd `realpath $0 | xargs dirname`
. ../ruby/ruby_settings.sh # TODO: ruby path
script/server -p 80 -b 127.0.0.1 &
echo $! > of.pid
