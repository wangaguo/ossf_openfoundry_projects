#This File is OpenFoundry Depolyment Configuration

#------------------# 
#  Generel config  #
#------------------#
ip_prefix = '192.168.3'
host = 'beta.openfoundry.org'
site_admin_mail = 'contact@openfoundry.org'
projects_upload_path = '/usr/upload'

#-------------------#
#  Session config
#  in session_store.rb
#-------------------#
session_key = '_of_new_key_'
session_domain = ".#{host}"
session_store = ':mem_cache_store'

session_memcache_namespace = 'of-#{Rails.env}'
session_memcache_server = "#{ip_prefix}.83:11211"

#-------------------#
#  Database config  #
#-------------------#
db_host = "#{ip_prefix}.10"
db_name_dev  = 'of_development'
db_name_test = 'of_test'
db_name_prod = 'of_development'
db_user = 'openfoundry'

##----------------------------#
##  Rails environment config  #
##----------------------------#
#rails_cache = ':memcache'

#----------------------#
#  Stomp server config
#  in broker.yml
#----------------------#
stomp_host = "#{ip_prefix}.83"
stomp_user = 'openfoundry'


#------------------------#
#  Ferret server config
#  in ferret_server.yml
#------------------------#
ferret_host = "#{ip_prefix}.83"


##------------------------#
##  Environment config
##  in environment.rb
##------------------------#
#
#cache_server = "#{ip_prefix}.80:11211"
#cache_server_namespace = 'of-#{Rails.env}'


#------------------------#
#  Redis server config
#  in environment.rb
#------------------------#

redis_server = "#{ip_prefix}.83"

#------------------------#
#  sso config
#  in sso.rb
#------------------------#

sso_ui_host = host
sso_of_auth_key = 'c1cac710-030f-012d-c173-0011254f08ff'

#------------------------#
#  sso config
#  in sso.rb
#------------------------#
tolk_user = 'ossf_trans'