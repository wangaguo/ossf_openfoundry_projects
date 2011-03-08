module Mongrel
  class HttpRequest
    alias_method :read_body_orig, :read_body if method_defined?(:read_body)
    def read_body(remain, total)
      @socket.close if remain > 10000
      read_body_orig(remain, total)
    end
  end
end
