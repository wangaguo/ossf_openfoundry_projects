#!/bin/sh
#OF_HOME=$1
OF_HOME=/usr/local/openfoundry

date

#fetch openfoundry from svn repostory
pkg_add -r subversion

svn checkout http://svn.openfoundry.org/openfoundry/trunk/of "${OF_HOME}"

#adduser openfoundry
pw group add openfoundry
pw user add -n openfoundry -u 5566 -g openfoundry -s /bin/csh

#install ruby, rails
su openfoundry -c "sh ${OF_HOME}/misc/install_ruby.sh"


PATH=/home/openfoundry/ruby/ruby/bin:${PATH}
export PATH
/home/openfoundry/ruby/ruby_setting.sh
gem build ${OF_HOME}/misc/openfoundry_dependent_gems-0.1.gemspec
gem install openfoundry_dependent_gems-0.1


#start up 
echo 'starting rails'
(cd ${OF_HOME}/;script/server) &

echo 'done'

