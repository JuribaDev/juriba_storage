module Domain
  module Entities
    class Blob
      attr_reader :id, :data, :size, :created_at, :storage_type

      def initialize(id:, data:, size: nil, created_at: nil, storage_type: nil)
        @id = id
        @data = data
        @size = size || calculate_size
        @created_at = created_at || Time.current.utc
        @storage_type = storage_type
        Rails.logger.debug("Initializing Blob with ID: #{@id}")
        validate!
      end

      def to_h
        {
          id: id,
          data: data,
          size: size.to_s,
          created_at: created_at.iso8601
        }
      end

      private

      def calculate_size
        Base64.decode64(data).bytesize
      rescue
        0
      end

      def validate!
        raise ArgumentError, "Blob ID cannot be blank" if @id.nil? || @id.strip.empty?
        raise ArgumentError, "Blob data cannot be blank" if @data.nil? || @data.strip.empty?
        raise ArgumentError, "Blob data must be Base64 encoded" unless Base64.strict_decode64(@data)
        raise ArgumentError, "Blob ID must be a valid UUID" unless valid_uuid?(@id)
      end

      def valid_uuid?(string_to_check)
        Rails.logger.debug("Validating UUID: #{string_to_check}, length: #{string_to_check.length}")
        # Proper UUID validation with regex pattern
        uuid_regex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

        uuid_regex.match?(string_to_check)
      end
    end
  end
end
