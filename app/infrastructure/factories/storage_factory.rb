module Infrastructure
  module Factories
    class StorageFactory < Domain::Interfaces::StorageFactory
      def initialize(config_service:)
        @config_service = config_service
      end

      def create
        storage_type = @config_service.storage_type.downcase

        case storage_type
        when "s3"
          Infrastructure::Strategies::S3Storage.new(config_service: @config_service)
        when "database"
          Infrastructure::Strategies::DatabaseStorage.new
        when "local"
          Infrastructure::Strategies::LocalStorage.new(config_service: @config_service)
        else
          raise ArgumentError, "Unsupported storage type: #{storage_type}"
        end
      end
    end
  end
end
