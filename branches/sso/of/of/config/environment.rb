# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when 
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.4' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here
  
  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )
  config.plugins = %W(authorization  activemessaging acts_as_redis_counter acts_as_taggable_on_steroids bundle-fu fckeditor http_accept_language nested_layouts resource_feeder run_later simply_helpful sortable_column_headers spandex_mem_cache_store validates_timeliness will_paginate)

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level 
  # (by default production uses :info, the others :debug)
  config.cache_store = [ :mem_cache_store, '127.0.0.1:11211:',
    {:namespace => "of-#{RAILS_ENV}", :timeout => nil } ]
   
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
  config.gem 'acts_as_ferret', :version => '= 0.4.3'
  #config.gem 'acts_as_taggable', :version => ">= 2.0.2" 
  config.gem 'ferret', :version => ">= 0.11.6" 
  # for gettext 2.0.0
  config.gem "locale"
  config.gem "locale_rails"
  config.gem "gettext"
  config.gem "gettext_activerecord"
  config.gem "gettext_rails"
  #config.gem "sdsykes-read_from_slave", :lib =>"read_from_slave", :source => "http://gems.github.com"
  config.gem "SyslogLogger", :lib => "syslog_logger"
  config.gem 'json', :version => ">= 1.1.2" 
  config.gem 'mongrel', :version =>  ">= 1.1.3" 
  config.gem 'rake', :version =>  ">= 0.8.1" 
  config.gem 'packr', :version =>  ">= 3.1.0" 
  config.gem 'redis'

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
  require 'user_environment'

  #ActionMailer::Base.delivery_method = :sendmail


  config.after_initialize {
    # add fulltext indexed SEARCH
    # for search in UTF-8
    UTF8_ANALYSIS_REGEX = 
      /([a-zA-Z]|[\xc0-\xdf][\x80-\xbf])+|[0-9]+|[\xe0-\xef][\x80-\xbf][\x80-\xbf]/
    GENERIC_ANALYZER = Ferret::Analysis::RegExpAnalyzer.new(UTF8_ANALYSIS_REGEX, true)
    DEFAULT_FIELD = [:name, :summary, 
	    :subject, :description, :requirement, :description_without_tag, :login]
    #for redis connection
    REDIS = Redis.new :host => '127.0.0.1'


    #require "lib/memory.rb"
    #require "lib/mongrel_size_limit.rb"
    #require 'bleak_house' if ENV['BLEAK_HOUSE']
    

  }

    # For Project Upload
#    OPENFOUNDRY_PROJECT_UPLOAD_PATH = '/usr/upload'

    # TODO: better naming
#    OPENFOUNDRY_SITE_ADMIN_EMAIL = 'contact@openfoundry.org'
#    OPENFOUNDRY_SITEMAIL_BATCH_MAX = 500 
#    OPENFOUNDRY_SESSION_EXPIRES_AFTER = 8 * 60 * 60 # in seconds
#    OPENFOUNDRY_VIEWVC_SVN_URL =  'http://of.openfoundry.org/viewvc-svn/'
#    OPENFOUNDRY_VIEWVC_CVS_URL =  'http://of.openfoundry.org/viewvc-cvs/'
#    OPENFOUNDRY_OF_URL = 'http://of.openfoundry.org'
#    OPENFOUNDRY_RT_URL = 'http://of.openfoundry.org/rt/'
#    OPENFOUNDRY_SYMPA_URL = 'http://of.openfoundry.org/sympa/'
#    OPENFOUNDRY_KWIKI_URL = 'http://of.openfoundry.org/kwiki/'
#    OPENFOUNDRY_HOMEPAGE_URL = 'http://%s.openfoundry.org'
#    OPENFOUNDRY_FTP_URL = 'ftp://ftp.of.openfoundry.org/'

#    OPENFOUNDRY_SITE_ADMIN_RUN_CODE_PATH = "#{RAILS_ROOT}/tmp/run_code.rb"
    # an Enumerable object.  TODO: not only ports but also addresses ?
#    OPENFOUNDRY_SITE_ADMIN_RUN_CODE_PORTS = (8000 .. 8005)

    #
    # important password! leak it may leak all your user data!!
    #
    #OPENFOUNDRY_JSON_DUMP_PASSWORD = 

    NSC_UPLOAD_DIR = "/usr/home/openfoundry/of/nsc_upload_dir" # don't forget to mkdir
    NSC_REVIEWERS_FILE = "/usr/home/openfoundry/of/nsc_upload_dir/reviewers.txt" # p u mapping
    NSC_REVIEWERS_LOGIN_FILTER = /^nscreviewer\d\d$/ # only accounts that can pass this filter
                                                     # may possiblely be a valid reviewer

    NSC_CURRENT_UPLOAD_FILTER = /./ # only types that match this filter can be uploaded
                                    # you may override it in initializers/environment_local.rb
    NSC_UPLOAD_FROM = "2009/01/01 00:00"
    NSC_UPLOAD_TO = "2009/12/31 23:59"
    NSC_CURRENT_YEAR = "98"
    NSC_REVIEW_OPENED = false
    NSC_ADMIN_ACCOUNT = "nsc_admin"
    
    UI_SCHEMA_CSS_HOST = 'freenix'

    #
    # sso testing variables
    #
    SSO_LOGIN = 'http://ssodev.openfoundry.org/sso/user/login'
    SSO_LOGOUT = 'http://ssodev.openfoundry.org/sso/user/logout'
    SSO_FETCH = 'http://ssodev.openfoundry.org/sso/site/fetch'
    SSO_OF_REGIST_KEY = 'c1cac710-030f-012d-c173-0011254f08ff'
    SSO_OF_LOGIN = 'http://ssodev.openfoundry.org/of/user/login'
		SSO_PERIOD_SYNC = 'http://ssodev.openfoundry.org/sso/sync.json'

    config.action_controller.relative_url_root = "/of"
end
