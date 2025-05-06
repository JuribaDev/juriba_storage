require 'rails_helper'

RSpec.describe Infrastructure::Services::CacheService do
  let(:config_service) { instance_double(Domain::Interfaces::ConfigurationService) }
  let(:redis_config) do
    {
      url: "redis://localhost:6379/1",
      cache_ttl: 3600
    }
  end
  let(:redis_client) { instance_double(Redis) }
  let(:blob_id) { "123e4567-e89b-12d3-a456-426614174000" } # Valid UUID format
  let(:valid_base64_data) { Base64.strict_encode64("test data") }
  let(:blob) do
    instance_double(
      Domain::Entities::Blob,
      id: blob_id,
      data: valid_base64_data,
      size: 100,
      created_at: Time.new(2023, 1, 1).utc,
      to_h: {
        id: blob_id,
        data: valid_base64_data,
        size: "100",
        created_at: Time.new(2023, 1, 1).utc.iso8601
      }
    )
  end

  subject(:cache_service) { described_class.new(config_service: config_service) }

  before do
    allow(config_service).to receive(:redis_config).and_return(redis_config)
    allow(Redis).to receive(:new).with(url: redis_config[:url]).and_return(redis_client)
  end

  describe "#get" do
    context "when the blob is in the cache" do
      let(:cached_data) do
        {
          id: blob_id,
          data: valid_base64_data,
          size: "100",
          created_at: Time.new(2023, 1, 1).utc.iso8601
        }.to_json
      end

      before do
        allow(redis_client).to receive(:get).with("blob:#{blob_id}").and_return(cached_data)
      end

      it "returns the deserialized blob" do
        result = cache_service.get(blob_id)

        expect(result).to be_a(Domain::Entities::Blob)
        expect(result.id).to eq(blob_id)
        expect(result.data).to eq(valid_base64_data)
        expect(result.size).to eq("100")
        expect(result.created_at).to eq(Time.new(2023, 1, 1).utc)
      end
    end

    context "when the blob is not in the cache" do
      before do
        allow(redis_client).to receive(:get).with("blob:#{blob_id}").and_return(nil)
      end

      it "returns nil" do
        result = cache_service.get(blob_id)
        expect(result).to be_nil
      end
    end
  end

  describe "#set" do
    before do
      allow(redis_client).to receive(:setex)
    end

    it "serializes the blob and stores it in Redis with the default TTL" do
      cache_service.set(blob_id, blob)

      expect(redis_client).to have_received(:setex).with(
        "blob:#{blob_id}",
        redis_config[:cache_ttl],
        blob.to_h.to_json
      )
    end

    it "uses the provided TTL if given" do
      custom_ttl = 7200
      cache_service.set(blob_id, blob, custom_ttl)

      expect(redis_client).to have_received(:setex).with(
        "blob:#{blob_id}",
        custom_ttl,
        blob.to_h.to_json
      )
    end
  end
end
