module Domain
  module Interfaces
    class ConfigurationService
      def storage_type
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def s3_config
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def local_storage_config
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def redis_config
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def jwt_config
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end
    end
  end
end
