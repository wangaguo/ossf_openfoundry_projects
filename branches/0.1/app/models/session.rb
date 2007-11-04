class Session < ActiveRecord::Base
  @@expires_at = lambda {7.days.ago.utc}

  belongs_to :user

  validates_format_of :session_id, :with => /^[a-f0-9]{32}$/i
  validates_format_of :host,       :with => /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/, :if => :host_not_nil?

  def active?
    updated_at > self.class.expires_at
  end

  def expired?
    !active?
  end

  protected
  def host_not_nil?
    !host.nil?
  end

  class << self
    def expires_at
      @@expires_at.call
    end

    def anonymous_sessions
      find( :all, :conditions => ["user_id IS NULL AND updated_at > ?", expires_at] )
    end

    def count_anonymous_sessions
      count ["user_id IS NULL AND updated_at > ?", expires_at]
    end

    def active_sessions
      find( :all, :conditions => ["updated_at > ?", expires_at] )
    end

    def expired_sessions
      find( :all, :conditions =>  ["updated_at < ?", expires_at] )
    end

    def destroy_expired_sessions!
      delete_all ["updated_at < ?", expires_at]
    end
  end

end
