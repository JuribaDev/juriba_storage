module Infrastructure
  class Container
    class << self
      def register(key, value = nil, &block)
        if block_given?
          registry[key] = block
        else
          registry[key] = -> { value }
        end
      end

      def resolve(key)
        resolver = registry[key]
        raise KeyError, "No dependency registered for #{key}" unless resolver

        resolver.call
      end

      def registry
        @registry ||= {}
      end

      def reset!
        @registry = {}
      end
    end
  end
end
