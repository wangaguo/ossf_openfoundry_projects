class CGI
  class Session
    def host
      @dbman.host
    end

    def host=(v)
      @dbman.host = v
    end

    def user
      @dbman.user
    end

    def user=(v)
      @dbman.user = v
    end
  end
end
