module UserSystem
  CONFIG = {
    # Source address for user emails
    :email_from => 'contact@openfoundry.org',

    # Destination email for system errors
    :admin_email => 'root@localhost',

    # Sent in emails to users
    # TODO: change to a better host name ??????!!!!
    :app_url => 'http://of.openfoundry.org/',

    # Sent in emails to users
    :app_name => 'OpenFoundry',

    # Email charset
    :mail_charset => 'utf-8',

    # Security token lifetime in hours
    :security_token_life_hours => 24,

    # Two column form input
    :two_column_input => true,
    
    #Subject prefix form user emails
    :email_subject_prefix => '[OpenFoundry]',

    #email available content-type
    :available_content_type => ['text/plain', 'text/html'],

    # Add all changeable user fields to this array.
    # They will then be able to be edited from the edit action. You
    # should NOT include the email field in this array.
    :changeable_fields => [ 'realname', 'language' ],

    # Set to true to allow delayed deletes (i.e., delete of record
    # doesn't happen immediately after user selects delete account,
    # but rather after some expiration of time to allow this action
    # to be reverted).
    :delayed_delete => false,

    # Default is one week
    :delayed_delete_days => 7,

    # Server environment
    :server_env => Rails.env
  }
end
