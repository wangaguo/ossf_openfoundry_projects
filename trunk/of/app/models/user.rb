require 'digest/sha1'
require 'of'

# this model expects a certain database layout and its based on the name/login pattern. 
class User < ActiveRecord::Base
  acts_as_authorized_user

  #add fulltext indexed SEARCH
  acts_as_ferret({
                 :fields => {:login => {:boost => 1.5,:store => :yes}#, 
                             #:firstname => {:boost => 0.8,:store => :yes}, 
                             #:lastname => {:boost => 0.8,:store => :yes}, 
                             #:name => {:boost => 0.8,:store => :yes} 
                            },
                 :single_index => true,
                 :default_field => [:login, :firstname, :lastname, :name]
                 }, { :analyzer => GENERIC_ANALYZER } )
                   

  #add tags
  acts_as_taggable
  # use tag_XXX prefix to set tags 
  # acts like post-modeled options
  def method_missing(method_name, *args)
    if /^t_(.*)=$/ =~ method_name.to_s
      act = ''
      case args.shift
      when true,1,'true'
        act = 'add'
      #when false,0,'false',nil
      else  
        act = 'remove'
      end
      tag_list.send(act, $1) 
    elsif /^t_([^=]*)$/ =~ method_name.to_s 
      return tag_list.names.include?($1)
    else
      super(method_name, *args)
    end 
  end

  # !use functions!
  #def admin_of
  #  is_admin_of_what
  #end
  #def member_of
  #  is_member_of_what
  #end

  def name
    "#{self.firstname} #{self.lastname}"
  end

  attr_accessor :new_password, :new_email
  
  def initialize(attributes = nil)
    super
    @new_password = false
    @new_email = false
  end

  def self.authenticate(login, pass)
    u = find( :first, :conditions => ["login = ? AND verified = 1 AND status = 0", login])
    return nil if u.nil?
    #find_first(["login = ? AND salted_password = ? AND verified = 1", login, salted_password(u.salt, hashed(pass))])
    find( :first, :conditions => ["login = ? AND salted_password = ? AND verified = 1", login, pass.crypt(u.salted_password)])
  end

  def self.authenticate_by_token(id, token, atts = {})
    include OpenFoundry::Message
    # 加上了用atts修改個人資料的功能 by tim
    # Allow logins for deleted accounts, but only via this method (and
    # not the regular authenticate call)
    u = find( :first, :conditions => ["id = ? AND security_token = ?", id, token])
    return nil if u.nil? or u.token_expired?
    return nil if false == u.update_expiry
    unless atts.empty?
      u.attributes = atts
      u.save
      atts['id'] = u.id
      atts['name'] = u.login
    else
      send_msg(TYPES[:user],ACTIONS[:create],{'id' => id, 'name' => u.login})
    end
    u
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

  def change_password(pass, confirm = nil)
    self.password = pass
    self.password_confirmation = confirm.nil? ? pass : confirm
    @new_password = true
  end
  
  def change_email(email, confirm = nil)
    self.email = email
    self.email_confirmation = confirm.nil? ? email : confirm
    @new_email  = true
  end
    
  protected

  attr_accessor :password, :password_confirmation, :email_confirmation

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

  def self.salted_password(salt, hashed_password)
    hashed(salt + hashed_password)
  end

  validates_presence_of :login, :on => :create
  validates_length_of :login, :within => 3..40, :on => :create
  #validates_uniqueness_of :login, :on => :create
  
  #validates_uniqueness_of :email, :on => :create
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_confirmation_of :email, :if => :validate_email?

  validates_presence_of :password, :if => :validate_password?
  validates_confirmation_of :password, :if => :validate_password?
  validates_length_of :password, { :minimum => 5, :if => :validate_password? }
  validates_length_of :password, { :maximum => 40, :if => :validate_password? }

#  #For "paranoid session store"
#  has_many   :sessions,   :conditions => ["#{Session.table_name}.updated_at > ?", Session.expires_at], :dependent => :delete_all
#
#  def self.online_users
#    find :all, :include => [:sessions], :conditions => "users.id = #{Session.table_name}.user_id"
#  end  

  # User.find(:all, :conditions => User.verified_users).size
  def self.verified_users(condition = 'true')
    if condition.is_a?(String)
      "(#{condition}) and (verified = 1)"
    elsif condition.is_a?(Array)
      [ verified_users(condition[0]), *condition[1 .. -1] ]
    else
      raise "wrong usage!"
    end
  end

  def validate
    if User.exists?(User.verified_users(['login = ? and id != ?', self.login, self.id]))
      errors.add(:login, "'#{login}' has already been used")
    end
    if User.exists?(User.verified_users(['email = ? and id != ?', self.email, self.id]))
      errors.add(:email, "'#{email}' has already been used")
    end
  end

  
end

