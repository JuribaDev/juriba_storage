require 'rails_helper'

RSpec.describe Infrastructure::Services::IdempotencyService do
  let(:config_service) { instance_double(Domain::Interfaces::ConfigurationService) }
  let(:redis_config) do
    {
      url: "redis://localhost:6379/1",
      idempotency_ttl: 86400
    }
  end
  let(:redis_client) { instance_double(Redis) }
  let(:request_id) { "request-123" }
  let(:blob_id) { "blob-456" }

  subject(:idempotency_service) { described_class.new(config_service: config_service) }

  before do
    allow(config_service).to receive(:redis_config).and_return(redis_config)
    allow(Redis).to receive(:new).with(url: redis_config[:url]).and_return(redis_client)
  end

  describe "#exists?" do
    context "when the request ID exists" do
      before do
        allow(redis_client).to receive(:exists?).with("idempotency:#{request_id}").and_return(true)
      end

      it "returns true" do
        expect(idempotency_service.exists?(request_id)).to be true
      end
    end

    context "when the request ID does not exist" do
      before do
        allow(redis_client).to receive(:exists?).with("idempotency:#{request_id}").and_return(false)
      end

      it "returns false" do
        expect(idempotency_service.exists?(request_id)).to be false
      end
    end
  end

  describe "#mark_as_processed" do
    before do
      allow(redis_client).to receive(:setex)
    end

    it "stores the blob ID with the request ID as key" do
      idempotency_service.mark_as_processed(request_id, blob_id)

      expect(redis_client).to have_received(:setex).with(
        "idempotency:#{request_id}",
        redis_config[:idempotency_ttl],
        blob_id
      )
    end
  end
end
