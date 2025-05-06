module Domain
  module Interfaces
    class CacheService
      def get(key)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def set(key, value, ttl = nil)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end
    end
  end
end
