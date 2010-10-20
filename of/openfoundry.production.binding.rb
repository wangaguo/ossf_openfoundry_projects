#This File is OpenFoundry Depolyment Configuration

#------------------# 
#  Generel config  #
#------------------#
ip_prefix = '192.168.6'
host = 'dev.openfoundry.org'

#-------------------#
#  Session config   #
#-------------------#
session_key = '_of_session_id'
session_domain = ".#{host}"
session_store = ':mem_cache_store'

session_memcache_namespace = 'of-#{RAILS_ENV}'
session_memcache_server = "#{ip_prefix}.1:11211"

#-------------------#
#  Database config  #
#-------------------#
db_host = "#{ip_prefix}.10"
db_name_dev  = 'ofdev'
db_name_test = 'of_test'
db_name_prod = 'ofdev'
db_user = 'ossf'

#----------------------------#
#  Rails environment config  #
#----------------------------#
rails_cache = ':memcache'

#----------------------#
#  Stomp server config  #
#----------------------#
stomp_host = "#{ip_prefix}.1"
stomp_user = 'openfoundry'


#------------------------#
#  Ferret server config  #
#------------------------#
ferret_host = "#{ip_prefix}.20"



