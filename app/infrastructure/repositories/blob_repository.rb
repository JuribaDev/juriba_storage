module Infrastructure
  module Repositories
    class BlobRepository < Domain::Interfaces::BlobRepository
      def initialize(storage_factory:)
        @storage_factory = storage_factory
      end

      def save(blob)
        # Create ActiveRecord model
        record = Infrastructure::Persistence::BlobTracker.find_or_initialize_by(id: blob.id)
        record.update!(
          blob_id: blob.id,
          blob_size: blob.size,
          storage_type: blob.storage_type,
          created_at: blob.created_at
        )

        blob
      end

      def find(id)
        record = Infrastructure::Persistence::BlobTracker.find_by(id: id)
        raise Domain::Errors::BlobNotFoundError, "Blob not found with ID: #{id}" unless record

        # Get the actual data from the storage
        storage = @storage_factory.create
        blob_data = storage.retrieve(id)

        Domain::Entities::Blob.new(
          id: id,
          data: blob_data[:data],
          size: blob_data[:size],
          created_at: blob_data[:created_at],
          storage_type: record.storage_type
        )
      end
    end
  end
end
