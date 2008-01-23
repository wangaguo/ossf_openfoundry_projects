# Allows ActionController to rebuild sessions non-destructively
class ActionController::CgiRequest
  def new_session
    if @session_options == false
      Hash.new
    else
      CGI::Session.new(@cgi, session_options_with_string_keys.merge("new_session" => true))
    end
  end

  def reset_session
    @session = new_session
  end

  def session
    unless @session
      if @session_options == false
        @session = Hash.new
      else
        stale_session_check! do
          if session_options_with_string_keys['new_session'] == true
            @session = new_session
          else
            begin
              @session = CGI::Session.new(@cgi, session_options_with_string_keys)
            rescue ArgumentError
              # Create a new session with a new key without destroying the old one
              @session = CGI::Session.new(@cgi, session_options_with_string_keys.merge("new_session" => true))
            end
          end
          @session['__valid_session']
        end
      end
    end
    @session
  end

end
