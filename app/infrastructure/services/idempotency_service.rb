module Infrastructure
  module Services
    class IdempotencyService < Domain::Interfaces::IdempotencyService
      def initialize(config_service:)
        redis_config = config_service.redis_config
        @redis = Redis.new(url: redis_config[:url])
        @ttl = redis_config[:idempotency_ttl]
      end

      def exists?(request_id)
        @redis.exists?("idempotency:#{request_id}")
      end

      def mark_as_processed(request_id, blob_id)
        @redis.setex("idempotency:#{request_id}", @ttl, blob_id)
      end
    end
  end
end
