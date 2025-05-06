module Infrastructure
  module Strategies
    class DatabaseStorage < Domain::Interfaces::BlobStorageStrategy
      def initialize
        # No need to create tables as they will be handled by Rails migrations
      end

      def store(blob)
        binary_data = Base64.decode64(blob.data)

        # Using Rails ORM to store the blob
        stored_blob = Infrastructure::Persistence::StoredBlob.find_or_initialize_by(id: blob.id)
        stored_blob.data = binary_data
        stored_blob.save!
      end

      def retrieve(blob_id)
        # Using Rails ORM to retrieve the blob
        stored_blob = Infrastructure::Persistence::StoredBlob.find_by(id: blob_id)

        raise Domain::Errors::BlobNotFoundError, "Blob not found with ID: #{blob_id}" unless stored_blob

        {
          data: Base64.strict_encode64(stored_blob.data),
          size: stored_blob.data.bytesize,
          created_at: stored_blob.created_at
        }
      end
    end
  end
end
