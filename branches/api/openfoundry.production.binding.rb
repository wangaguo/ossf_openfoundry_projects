#This File is OpenFoundry Depolyment Configuration

#------------------# 
#  Generel config  #
#------------------#
ip_prefix = '127.0.'
host = 'api.openfoundry.org'
site_admin_mail = 'mouse.kaworu@gmail.com'

#-------------------#
#  Session config
#  in session_store.rb
#-------------------#
session_key = '_ossf_api_'
session_domain = ".#{host}"
session_store = ':mem_cache_store'

session_memcache_namespace = 'api-#{RAILS_ENV}'
session_memcache_server = "#{ip_prefix}.0.1:11211"

#-------------------#
#  Database config  #
#-------------------#
db_host = "#{ip_prefix}.0.1"
db_name_dev  = 'api_development'
db_name_test = 'api_test'
db_name_prod = 'api_development'
db_user = 'kaworu'

#----------------------------#
#  Rails environment config  #
#----------------------------#
rails_cache = ':memcache'

#----------------------#
#  Stomp server config
#  in broker.yml
#----------------------#
stomp_host = "#{ip_prefix}.0.1"
stomp_user = 'stomp'


#------------------------#
#  Ferret server config
#  in ferret_server.yml
#------------------------#
ferret_host = "#{ip_prefix}.0.1"


#------------------------#
#  Environment config
#  in environment.rb
#------------------------#

cache_server = "127.0.0.1:11211"
cache_server_namespace = 'api-#{RAILS_ENV}'


#------------------------#
#  Redis server config
#  in environment.rb
#------------------------#

redis_server = "127.0.0.1"

#------------------------#
#  sso config
#  in sso.rb
#------------------------#

sso_ui_host = '140.109..20'
sso_of_auth_key = 'c1cac710-030f-012d-c173-0011254f08ff'

#------------------------#
#  sso config
#  in sso.rb
#------------------------#
tolk_user = 'ossf_trans'
