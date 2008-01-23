#require 'mysql'

class ActiveRecord::ConnectionAdapters::MysqlAdapter
  attr_reader :connection
end

class ParanoidMysqlSession
  attr_accessor :id,
                :session_id,
                :host,
                :user,
                :data

  cattr_accessor :eager_session_creation
  @@eager_session_creation = false

  def initialize(session_id, data, host, user)
    @session_id = session_id
    @id         = nil
    @data       = data
    @host       = host
    @user       = user
  end

  def mysqlify(v)
    v.nil? ? 'NULL' :  "'#{v}'"
  end

  def update_session(data)
    con = self.class.connection
    unless @id.nil?
      con.query("UPDATE sessions SET `updated_at`=UTC_TIMESTAMP(),
                                      `host`=#{mysqlify(@host)},
                                      `user_id`=#{mysqlify(@user)},
                                      `data`='#{Mysql::quote(data)}'
                        WHERE id=#{@id}")
    else
      con.query("INSERT INTO sessions (`created_at`, `updated_at`, `session_id`, `host`, `user_id`, `data`)
                VALUES (UTC_TIMESTAMP(), UTC_TIMESTAMP(), '#{@session_id}', #{mysqlify(@host)}, #{mysqlify(@user)}, '#{Mysql::quote(data)}')")
      @id = con.insert_id
    end
  end

  def destroy
    self.class.delete_all("session_id='#{session_id}'")
  end

  class << self
    def connection
      Session.connection.connection
    end

    def find_session(session_id)
      con = connection
      con.query_with_result = true

      result = con.query("SELECT id, data, host, user_id, updated_at
                          FROM sessions WHERE `session_id`='#{session_id}'
                          LIMIT 1")
      my_session = nil
      result.each do |row|
        raise CGI::Session::NoSession if row[4].to_time < Session.expires_at
        my_session = new(session_id, row[1], row[2], row[3])
        my_session.id = row[0]
      end
      result.free
      my_session
    end

    def create_session( session_id, data )
      new_session = new(session_id, data, nil, nil)
      if @@eager_session_creation
        con = connection
        con.query("INSERT INTO sessions (`created_at`, `updated_at`, `session_id`, `data`)
                  VALUES (UTC_TIMESTAMP(), UTC_TIMESTAMP(), '#{session_id}', '#{Mysql::quote(data)}')")
        new_session.id = con.insert_id
      end
      new_session
    end

    def delete_all(condition = nil)
      if condition
        connection.query("DELETE FROM sessions WHERE #{condition}")
      else
        connection.query("DELETE FROM sessions")
      end
    end
  end

end
