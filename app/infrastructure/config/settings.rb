module Infrastructure
  module Config
    class Settings
      class << self
        def storage_type
          ENV.fetch("STORAGE_TYPE", "s3")
        end

        def s3_config
          {
            bucket: ENV.fetch("MINIO_BUCKET", "blobs"),
            access_key_id: ENV.fetch("MINIO_ACCESS_KEY_ID", ""),
            secret_access_key: ENV.fetch("MINIO_SECRET_ACCESS_KEY", ""),
            endpoint: ENV.fetch("MINIO_ENDPOINT", "http://localhost:9000"),
            region: ENV.fetch("MINIO_REGION", "us-east-1"),
            force_path_style: ENV.fetch("MINIO_FORCE_PATH_STYLE", "true") == "true"
          }
        end

        def local_storage_config
          {
            path: ENV.fetch("LOCAL_STORAGE_PATH", Rails.root.join("/storage/blobs").to_s)
          }
        end

        def redis_config
          {
            url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
            cache_ttl: ENV.fetch("REDIS_CACHE_TTL", "3600").to_i,
            idempotency_ttl: ENV.fetch("REDIS_IDEMPOTENCY_TTL", "86400").to_i
          }
        end

        def jwt_config
          {
            secret: ENV.fetch("JWT_SECRET", "development_secret"),
            expiration: ENV.fetch("JWT_EXPIRATION", "86400").to_i
          }
        end
      end
    end
  end
end
