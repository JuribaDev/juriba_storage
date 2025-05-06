module Domain
  module Interfaces
    class BlobStorageStrategy
      def store(blob)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def retrieve(blob_id)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end
    end
  end
end
