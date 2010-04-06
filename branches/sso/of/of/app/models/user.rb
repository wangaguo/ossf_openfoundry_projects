require 'digest/sha1'
require 'of'

# this model expects a certain database layout and its based on the name/login pattern. 
class User < ActiveRecord::Base
  composed_of :tz, :class_name => 'TimeZone', :mapping => %w( timezone timezone )
  acts_as_authorized_user

  #add fulltext indexed SEARCH
  acts_as_ferret({
                 :fields => {:login => {:boost => 1.5,:store => :yes}, 
                             #:firstname => {:boost => 0.8,:store => :yes}, 
                             #:lastname => {:boost => 0.8,:store => :yes}, 
                             :name => {:boost => 0.8,:store => :yes} 
                            },
                 :single_index => true
                 }, { :analyzer => GENERIC_ANALYZER, :default_field => DEFAULT_FIELD } )
                 
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

  attr_accessor :new_password, :new_email
  attr_accessor :password, :password_confirmation, :email_confirmation
  attr_accessor :old_password
  
  def initialize(attributes = {})
    super
    @new_password = false
    @new_email = false
    @old_password = ''
  end

  def token_expired?
    self.security_token and self.token_expiry and (Time.now > self.token_expiry)
  end

  def update_expiry
    write_attribute('token_expiry', [self.token_expiry, Time.at(Time.now.to_i + 600 * 1000)].min)
    write_attribute('authenticated_by_token', true)
    write_attribute("verified", 1)
    update_without_callbacks
  end

  def generate_security_token(hours = nil)
    if not hours.nil? or self.security_token.nil? or self.token_expiry.nil? or 
        (Time.now.to_i + token_lifetime / 2) >= self.token_expiry.to_i
      return new_security_token(hours)
    else
      return self.security_token
    end
  end

  def set_delete_after
    hours = UserSystem::CONFIG[:delayed_delete_days] * 24
    write_attribute('status', 4)
    write_attribute('delete_after', Time.at(Time.now.to_i + hours * 60 * 60))

    # Generate and return a token here, so that it expires at
    # the same time that the account deletion takes effect.
    return generate_security_token(hours)
  end

  def change_password(old_pass, new_pass, new_pass_confirm = nil)
    self.old_password = old_pass
    self.password = new_pass
    self.password_confirmation = new_pass_confirm.nil? ? new_pass : new_pass_confirm
    @new_password = true
  end
  
  def change_email(email, confirm = nil)
    self.email = email
    self.email_confirmation = confirm.nil? ? email : confirm
    @new_email  = true
  end
      
  def validate
    #for change_password by valid user
    if(@new_password and (not old_password.blank?) and 
      old_password.crypt(self.salted_password) != self.salted_password)
      errors.add(:old_password, _('Old Password Incorrect')) 
    end
    #for username and email check
    cond = ["login = ? and #{User.verified_users}", login]
    cond = [cond[0] + " and id <> ?", cond[1], id] unless new_record?
    errors.add(:login, "'#{login}' has already been used") if User.exists?(cond)
    cond = ["email = ? and #{User.verified_users}", email]
    cond = [cond[0] + " and id <> ?", cond[1], id] unless new_record?
    errors.add(:email, "'#{email}' has already been used") if User.exists?(cond)
  end
  
  def validate_password?
    @new_password
  end
  
  def validate_email?
    @new_email
  end

  def self.hashed(str)
    return Digest::SHA1.hexdigest("change-me--#{str}--")[0..39]
  end

  after_save '@new_password = false'
  after_save '@new_email = false'
  after_validation :crypt_password
  def crypt_password
    if @new_password
      write_attribute("salt", self.class.hashed("salt-#{Time.now}"))
      #write_attribute("salted_password", self.class.salted_password(salt, self.class.hashed(@password)))
      write_attribute("salted_password", (@password).crypt('$1$' + rand(100000).to_s))
    end
  end

  def new_security_token(hours = nil)
    write_attribute('security_token', self.class.hashed(self.salted_password + Time.now.to_i.to_s + rand.to_s))
    write_attribute('token_expiry', Time.at(Time.now.to_i + token_lifetime(hours)))
    update_without_callbacks
    return self.security_token
  end

  def token_lifetime(hours = nil)
    if hours.nil?
      UserSystem::CONFIG[:security_token_life_hours] * 60 * 60
    else
      hours * 60 * 60
    end
  end

  LOGIN_REGEX = /^[a-zA-Z][0-9a-zA-Z_]{2,13}$/ #14
  EMAIL_REGEX = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i  
  validates_presence_of :login, :on => :create
  validates_format_of :login, :with => LOGIN_REGEX, :on => :create
  validates_length_of :login, :within => 3..14, :on => :create
  
  validates_format_of :email, :with => EMAIL_REGEX
  validates_confirmation_of :email, :if => :validate_email?

  validates_presence_of :password, :if => :validate_password?
  validates_confirmation_of :password, :if => :validate_password?
  validates_length_of :password, { :minimum => 5, :if => :validate_password? }
  validates_length_of :password, { :maximum => 40, :if => :validate_password? }

  def self.authenticate(login, pass)
    u = find( :first, :conditions => ["login = ? AND verified = 1 AND status = 0", login])
    return nil if u.nil?
    #find_first(["login = ? AND salted_password = ? AND verified = 1", login, salted_password(u.salt, hashed(pass))])
    find( :first, :conditions => ["login = ? AND salted_password = ? AND verified = 1", login, pass.crypt(u.salted_password)])
  end

  def self.authenticate_by_sso(login)
  	find( :first, :conditions => ["login = ? AND verified = 1", login] )
  end

  def self.is_the_same_loginname_used?(u)
    u.verified ==0 and User.valid_users.count(:conditions => "login = '#{u.login}'") > 0
  end

  def self.authenticate_by_token(id, token, atts = {})
    include OpenFoundry::Message
    # 加上了用atts修改個人資料的功能 by tim
    # Allow logins for deleted accounts, but only via this method (and
    # not the regular authenticate call)
    u = find( :first, :conditions => ["id = ? AND security_token = ?", id, token])
    return nil if atts.empty? and is_the_same_loginname_used?(u)
    return nil if u.nil? or u.token_expired?
    return nil if false == u.update_expiry
    unless atts.empty?#update atts
      u.attributes = atts
      u.save
      atts['id'] = u.id
      atts['name'] = u.login
      send_msg(TYPES[:user],ACTIONS[:update],{'id' => id, 'name' => u.login, 'email' => u.email})
    else#registing email
      send_msg(TYPES[:user],ACTIONS[:create],{'id' => id, 'name' => u.login, 'email' => u.email})
      u.ferret_create
    end
    u
  end

  # User.find(:all, :conditions => User.verified_users).size
  def self.verified_users(options = {})
    a = options[:alias]
    if a;a += '.';end        
    "(#{a}verified = 1)"    
  end
  
  def self.salted_password(salt, hashed_password)
    hashed(salt + hashed_password)
  end

  named_scope :valid_users, :conditions => { :verified => 1 }

  #
  # BE CAREFUL!!
  #
  # 
  # > User.select_only("id, login").first
  #   
  # SELECT id, login FROM `users` LIMIT 1
  #
  # > Role.find(2).users.select_only("login")
  #   ....
  # SELECT * FROM `users` INNER JOIN  ....   <==== FAILED !!!!
  #
  # > Role.find(2).users.select_only("login").all
  #   ....
  # SELECT login FROM `users` INNER JOIN ....
  #
  # see: Association proxies using class methods with named scopes 
  # http://rails.lighthouseapp.com/projects/8994/tickets/1677
  named_scope :select_only, lambda {|s| { :select => s }} # can not be named as "select"
end

