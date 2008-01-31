require 'active_record'
require 'cgi'
require 'cgi/session'
require 'base64'

require 'cgi_session_hack'

class ParanoidSqlSessionStore
  cattr_accessor :session_class
  @@session_class = ParanoidMysqlSession

  def initialize( session, option = nil )
    if @session = @@session_class.find_session(session.session_id)
      @data = unmarshalize(@session.data)
    else
      @session = @@session_class.create_session(session.session_id, marshalize({}))
      @data = {}
    end
  end

  def close
    if @session
      @session.update_session(marshalize(@data))
      @session = nil
    end
  end

  def delete
    if @session
      @session.destroy
      @session = nil
    end
  end

  def restore
    if @session
      @data = unmarshalize(@session.data)
    end
  end

  def update
    if @session
      @session.update_session(marshalize(@data))
    end
  end

  def host=( v )
    @session.host = v
  end

  def host
    @session.host
  end

  def user=( v )
    @session.user = v
  end

  def user
    @session.user
  end

  private
  def unmarshalize( data )
    Marshal.load(Base64.decode64(data))
  end

  def marshalize( data )
    Base64.encode64(Marshal.dump(data))
  end

end
