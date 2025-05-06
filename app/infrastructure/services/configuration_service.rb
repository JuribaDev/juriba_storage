module Infrastructure
  module Services
    class ConfigurationService < Domain::Interfaces::ConfigurationService
      def storage_type
        Infrastructure::Config::Settings.storage_type
      end

      def s3_config
        Infrastructure::Config::Settings.s3_config
      end

      def local_storage_config
        Infrastructure::Config::Settings.local_storage_config
      end

      def redis_config
        Infrastructure::Config::Settings.redis_config
      end

      def jwt_config
        Infrastructure::Config::Settings.jwt_config
      end
    end
  end
end
