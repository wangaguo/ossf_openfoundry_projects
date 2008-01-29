#!/bin/sh
cd `realpath $0 | xargs dirname`
. ~/ruby/ruby_settings.sh
script/server
