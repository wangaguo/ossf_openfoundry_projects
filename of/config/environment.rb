# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  config.log_level = :info

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store
  config.action_controller.session_store = :active_record_store
   
  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper, 
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql
  config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
  # DEFAULT_REDIRECTION_HASH
  DEFAULT_REDIRECTION_HASH = { :controller => 'user', :action => 'login' }
  STORE_LOCATION_METHOD = :store_location

  # add required gems 
  config.gem 'cgi_multipart_eof_fix', :version => '>= 2.5.0'
  config.gem 'acts_as_ferret', :version => '>= 0.4.3'
  config.gem 'acts_as_taggable', :version => ">= 2.0.2" 
  config.gem 'ferret', :version => ">= 0.11.6" 
  config.gem 'gettext', :version => ">= 1.91.0" 
  config.gem 'json', :version => ">= 1.1.2" 
  config.gem 'mongrel', :version =>  ">= 1.1.3" 
  config.gem 'rake', :version =>  ">= 0.8.1" 
  #config.gem 'rmagick', :version =>  ">= 1.15.12" 
  config.gem 'tzinfo', :version =>  ">= 0.3.6" 
  #config.gem 'ruby-openid', :version =>  ">= 2.1.2"

  config.time_zone = 'Taipei' 

  # Add new inflection rules using the following format 
  # (all these examples are active by default):
  # Inflector.inflections do |inflect|
  #   inflect.plural /^(ox)$/i, '\1en'
  #   inflect.singular /^(ox)en/i, '\1'
  #   inflect.irregular 'person', 'people'
  #   inflect.uncountable %w( fish sheep )
  # end

  # Add new mime types for use in respond_to blocks:
  # Mime::Type.register "text/richtext", :rtf
  # Mime::Type.register "application/x-mobile", :mobile

  # Include your application configuration below
  require 'environments/user_environment'

  #ActionMailer::Base.delivery_method = :sendmail


  config.after_initialize {
    # add fulltext indexed SEARCH
    # for search in UTF-8
    UTF8_ANALYSIS_REGEX = 
      /([a-zA-Z]|[\xc0-\xdf][\x80-\xbf])+|[0-9]+|[\xe0-\xef][\x80-\xbf][\x80-\xbf]/
    GENERIC_ANALYZER = Ferret::Analysis::RegExpAnalyzer.new(UTF8_ANALYSIS_REGEX, true)

    # store host, user_id in sessions
    require 'cgi_session_activerecord_store_hack'
    
    #require "lib/memory.rb"
    #require "lib/mongrel_size_limit.rb"
    #require 'bleak_house' if ENV['BLEAK_HOUSE']
    
    # For Project Upload
    OPENFOUNDRY_PROJECT_UPLOAD_PATH = '/usr/upload'

    # TODO: better naming
    OPENFOUNDRY_SITE_ADMIN_EMAIL = 'contact@openfoundry.org'
    OPENFOUNDRY_SESSION_EXPIRES_AFTER = 8.hours # in seconds
    OPENFOUNDRY_VIEWVC_URL =  'http://of.openfoundry.org/viewvc/'
    OPENFOUNDRY_RT_URL = 'http://of.openfoundry.org/rt/'
    OPENFOUNDRY_SYMPA_URL = 'http://of.openfoundry.org/sympa/'
    OPENFOUNDRY_KWIKI_URL = 'http://of.openfoundry.org/kwiki/'
    OPENFOUNDRY_HOMEPAGE_URL = 'http://%s.openfoundry.org'
    #
    # important password! leak it may leak all your user data!!
    #
    #OPENFOUNDRY_JSON_DUMP_PASSWORD = 
  }

end
