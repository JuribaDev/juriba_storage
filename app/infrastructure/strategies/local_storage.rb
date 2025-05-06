module Infrastructure
  module Strategies
    class LocalStorage < Domain::Interfaces::BlobStorageStrategy
      def initialize(config_service:)
        @storage_path = config_service.local_storage_config[:path]
        FileUtils.mkdir_p(@storage_path) unless Dir.exist?(@storage_path)
      end

      def store(blob)
        path = File.join(@storage_path, blob.id)

        # Write metadata file
        File.write("#{path}.meta", {
          created_at: blob.created_at.iso8601
        }.to_json)

        # Write actual data
        File.binwrite(path, Base64.decode64(blob.data))
      end

      def retrieve(blob_id)
        path = File.join(@storage_path, blob_id)
        meta_path = "#{path}.meta"

        raise Domain::Errors::BlobNotFoundError, "Blob not found with ID: #{blob_id}" unless File.exist?(path) && File.exist?(meta_path)

        data = File.binread(path)
        metadata = JSON.parse(File.read(meta_path))

        {
          data: Base64.strict_encode64(data),
          size: data.bytesize,
          created_at: Time.parse(metadata["created_at"])
        }
      end
    end
  end
end
