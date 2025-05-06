module Domain
  module Interfaces
    class BlobRepository
      def save(blob)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def find(id)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end
    end
  end
end
