#This File is OpenFoundry Depolyment Configuration

#------------------# 
#  Generel config  #
#------------------#
ip_prefix = '140.109'
host = 'ssodev.openfoundry.org'
site_admin_mail = 'hyder.ossf@gmail.com'

#-------------------#
#  Session config
#  in session_store.rb
#-------------------#
session_key = '_of_session_id'
session_domain = ".#{host}"
session_store = ':mem_cache_store'

session_memcache_namespace = 'of-#{RAILS_ENV}'
session_memcache_server = "#{ip_prefix}.22.15:11211"

#-------------------#
#  Database config  #
#-------------------#
db_host = "#{ip_prefix}.22.140"
db_name_dev  = 'of_development'
db_name_test = 'of_test'
db_name_prod = 'of_development'
db_user = 'openfoundry'

#----------------------------#
#  Rails environment config  #
#----------------------------#
rails_cache = ':memcache'

#----------------------#
#  Stomp server config
#  in broker.yml
#----------------------#
stomp_host = "#{ip_prefix}.22.140"
stomp_user = 'openfoundry'


#------------------------#
#  Ferret server config
#  in ferret_server.yml
#------------------------#
ferret_host = "#{ip_prefix}.22.15"


#------------------------#
#  Environment config
#  in environment.rb
#------------------------#

cache_server = "127.0.0.1:11211"
cache_server_namespace = 'of-#{RAILS_ENV}'


#------------------------#
#  Redis server config
#  in environment.rb
#------------------------#

redis_server = "127.0.0.1"

#------------------------#
#  sso config
#  in sso.rb
#------------------------#

sso_ui_host = '140.109.22.20'
sso_of_auth_key = 'FIX ME'
