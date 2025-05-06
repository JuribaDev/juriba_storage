module Infrastructure
  module Services
    class CacheService < Domain::Interfaces::CacheService
      def initialize(config_service:)
        redis_config = config_service.redis_config
        @redis = Redis.new(url: redis_config[:url])
        @ttl = redis_config[:cache_ttl]
      end

      def get(key)
        data = @redis.get("blob:#{key}")
        return nil unless data

        deserialize(data)
      end

      def set(key, blob, ttl = nil)
        ttl ||= @ttl
        @redis.setex("blob:#{key}", ttl, serialize(blob))
      end

      private

      def serialize(blob)
        blob.to_h.to_json
      end

      def deserialize(data)
        hash = JSON.parse(data, symbolize_names: true)

        Domain::Entities::Blob.new(
          id: hash[:id],
          data: hash[:data],
          size: hash[:size],
          created_at: Time.parse(hash[:created_at])
        )
      end
    end
  end
end
