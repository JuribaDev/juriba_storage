module Application
  module Services
    class BlobService
      def initialize(blob_repository:, storage_factory:, cache_service:, idempotency_service:, config_service:)
        @blob_repository = blob_repository
        @storage_factory = storage_factory
        @cache_service = cache_service
        @idempotency_service = idempotency_service
        @config_service = config_service
      end

      def store_blob(id:, data:, request_id:)
        # Check for idempotency
        return find_blob(id) if @idempotency_service.exists?(request_id)

        begin
          # Validate the base64 data
          validate_base64!(data)

          # Create blob entity
          blob = Domain::Entities::Blob.new(
            id: id,
            data: data,
            storage_type: @config_service.storage_type
          )
        rescue ArgumentError => e
          Rails.logger.error("Invalid blob data: #{e.message}")
          raise Domain::Errors::InvalidBlobDataError, e.message
        rescue Domain::Errors::InvalidBase64Error => e
          Rails.logger.error("Invalid base64 data: #{e.message}")
          raise Domain::Errors::InvalidBlobDataError, e.message
        end

        begin
          # Store in the selected storage
          storage = @storage_factory.create
          storage.store(blob)

          # Save metadata in repository
          @blob_repository.save(blob)

          # Mark request as processed for idempotency
          @idempotency_service.mark_as_processed(request_id, id)

          blob
        rescue => e
          # Log error details for debugging
          Rails.logger.error("Error storing blob: #{e.message}")
          Rails.logger.error("Error class: #{e.class}")
          Rails.logger.error("Backtrace: #{e.backtrace[0..5].join("\n")}")
          raise Domain::Errors::BlobStorageError, e.message
        end
      end

      def find_blob(id)
        # Check cache first
        cached_blob = @cache_service.get(id)
        return cached_blob if cached_blob

        # If not in cache, find in repository
        blob = @blob_repository.find(id)

        # Store in cache for future requests
        @cache_service.set(id, blob) if blob

        blob
      rescue => e
        Rails.logger.error("Error finding blob: #{e.message}")
        raise Domain::Errors::BlobNotFoundError, "Blob with ID #{id} not found"
      end

      private

      def validate_base64!(data)
        Base64.strict_decode64(data)
      rescue ArgumentError => e
        raise Domain::Errors::InvalidBase64Error, "Invalid Base64 encoding: #{e.message}"
      end
    end
  end
end
