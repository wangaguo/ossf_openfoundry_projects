#!/bin/sh
cd `realpath $0 | xargs dirname`
. ../ruby/ruby_settings.sh # TODO: ruby path
script/server &
echo $! > of.pid
