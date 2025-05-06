module Domain
  module Interfaces
    class StorageFactory
      def create
        raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
      end
    end
  end
end
