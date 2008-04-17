#!/bin/sh
DB_PREFIX=$1
DB_USER=$2
DB_PASS=$3
DB_HOST=$4

# for replacing database.yml only
export DB_PREFIX; export DB_USER; export DB_PASS; export DB_HOST
: ${PACKAGEROOT:=ftp://ftp.tw.freebsd.org}

date

pw group add openfoundry
pw user add -n openfoundry -u 5566 -g openfoundry -s /bin/csh -m

env PACKAGEROOT=$PACKAGEROOT pkg_add -r subversion 
env PACKAGEROOT=$PACKAGEROOT pkg_add -r mysql50-client 
env PACKAGEROOT=$PACKAGEROOT pkg_add -r ImageMagick


su openfoundry -c sh -x <<'ROR'
  cd ${HOME}
  #fetch openfoundry from svn repostory
  svn co http://svn.openfoundry.org/openfoundry/trunk/of
  sh of/misc/install_ruby.sh
  PATH="${HOME}/ruby/ruby/bin:${PATH}"
  export PATH
  gem build "/home/openfoundry/of/misc/openfoundry_dependent_gems-0.1.gemspec"
  gem install openfoundry_dependent_gems-0.1
  cd of
  ruby -pe 'gsub(/--(\w+)--/) { ENV.has_key?($1) ? ENV[$1] : raise("no #{$1} in ENV") }' config/database.yml.template > config/database.yml
  #rake db:create
  #echo $DB_PASS | mysqladmin -u "$DB_USER" -h "$DB_HOST" -p create "${DB_PREFIX}_development"
  #echo $DB_PASS | mysqladmin -u "$DB_USER" -h "$DB_HOST" -p create "${DB_PREFIX}_test"
  #echo $DB_PASS | mysqladmin -u "$DB_USER" -h "$DB_HOST" -p create "${DB_PREFIX}_production"
  rake db:schema:load
  rake db:fixtures:load
ROR

#install /usr/local/rc.d/script
cp /home/openfoundry/of/misc/openfoundry /usr/local/etc/rc.d/
#start openfoundry
/usr/local/etc/rc.d/openfoundry start

date
