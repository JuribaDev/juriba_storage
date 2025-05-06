module Domain
  module Interfaces
    class IdempotencyService
      def exists?(request_id)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end

      def mark_as_processed(request_id, resource_id)
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end
    end
  end
end
