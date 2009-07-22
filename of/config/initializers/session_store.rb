# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_of_session_id',
  :secret      => '30d096717228ac2c04e07369dd1692ba46e12a2c9666d9ae49161af470b3212d59dfeb711dd94f0d44d7edf2cfc8bd239488a5eba84e3fb2c6317a93e0714b9c',
  :expire_after => 8.hours,
  :domain      => '.of.openfoundry.org',
  #this is for mem_cache_store
  :namespace   => "of-#{RAILS_ENV}",
  :memcache_server => '192.168.0.20:11211'

}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :mem_cache_store
