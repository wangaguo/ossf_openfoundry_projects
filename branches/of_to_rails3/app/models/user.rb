require 'digest/sha1'
require 'of'

# this model expects a certain database layout and its based on the name/login pattern. 
class User < ActiveRecord::Base
  composed_of :tz, :class_name => 'TimeZone', :mapping => %w( timezone timezone )
  acts_as_authorized_user

  #add fulltext indexed SEARCH
#  acts_as_ferret({
#                 :fields => {:login => {:boost => 1.5,:store => :yes}, 
#                             #:firstname => {:boost => 0.8,:store => :yes}, 
#                             #:lastname => {:boost => 0.8,:store => :yes}, 
#                             :name => {:boost => 0.8,:store => :yes} 
#                            },
#                 :single_index => true
#                 }, { :analyzer => GENERIC_ANALYZER, :default_field => DEFAULT_FIELD } )

  after_create :send_rt_create_msg
  after_update :send_rt_update_msg

  def send_rt_create_msg
    send_msg(:user, :create, {:id => id, :name => login, :email => email})
  end               

  def send_rt_update_msg
    send_msg(:user, :update, {:id => id, :name => login, :email => email})
  end          

  # disable ferret search if not verified        
  def ferret_enabled?(is_bulk_index = false)
    (verified == 1) && @ferret_disabled.nil? && (is_bulk_index || self.class.ferret_enabled?)
  end

  def functions_for(authorizable_id, authorizable_type = 'Project')
    rtn = []
    roles.each do |r|
      next unless( r.authorizable_id == authorizable_id and 
          r.authorizable_type == authorizable_type )
      r.functions.each do |f|
        rtn << f unless rtn.member?(f)
      end
    end
    rtn
  end
  
  def name
    if self.t_conceal_realname
      ''
    else
      self.realname
    end
  end

  #add tags
  acts_as_taggable
  # use tag_XXX prefix to set tags 
  # acts like post-modeled options
  def method_missing(method_name, *args)
    if /^t_(.*)=$/ =~ method_name.to_s
      act = ''
      case args.shift
      when '1','true',true
        act = 'add'
      when '0','false',false
        act = 'remove'
      else
        raise ArgumentError
      end
      tag_list.send(act, $1) 
    elsif /^t_([^=]*)$/ =~ method_name.to_s 
      return tag_list.names.include?($1)
    else
      super(method_name, *args)
    end 
  end

  LOGIN_REGEX = /^[a-zA-Z][0-9a-zA-Z_]{2,13}$/ #14
  EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i  

  def self.authenticate_by_sso(login)
  	find( :first, :conditions => ["login = ?", login] )
  end

  # User.find(:all, :conditions => User.verified_users).size
  def self.verified_users(options = {})
    a = options[:alias]
    if a;a += '.';end
    "(#{a}verified = 1)"
  end

  scope :valid_users, :conditions => { :verified => 1 }
end

