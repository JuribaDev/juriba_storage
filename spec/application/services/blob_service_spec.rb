require 'rails_helper'

RSpec.describe Application::Services::BlobService do
  let(:blob_repository) { instance_double(Domain::Interfaces::BlobRepository) }
  let(:storage_factory) { instance_double(Domain::Interfaces::StorageFactory) }
  let(:storage_strategy) { instance_double(Domain::Interfaces::BlobStorageStrategy) }
  let(:cache_service) { instance_double(Domain::Interfaces::CacheService) }
  let(:idempotency_service) { instance_double(Domain::Interfaces::IdempotencyService) }
  let(:config_service) { instance_double(Domain::Interfaces::ConfigurationService) }

  let(:valid_id) { "123e4567-e89b-12d3-a456-426614174000" } # Valid UUID format
  let(:valid_data) { Base64.strict_encode64("test data") }
  let(:request_id) { "request-123" }
  let(:storage_type) { "s3" }

  subject(:service) do
    described_class.new(
      blob_repository: blob_repository,
      storage_factory: storage_factory,
      cache_service: cache_service,
      idempotency_service: idempotency_service,
      config_service: config_service
    )
  end

  before do
    allow(storage_factory).to receive(:create).and_return(storage_strategy)
    allow(config_service).to receive(:storage_type).and_return(storage_type)
    # Set up mocks as spies to track method calls
    allow(storage_strategy).to receive(:store)
    allow(blob_repository).to receive(:save)
    allow(blob_repository).to receive(:find)
  end

  describe "#store_blob" do
    context "when the request is idempotent" do
      let(:existing_blob) { instance_double(Domain::Entities::Blob) }

      before do
        allow(idempotency_service).to receive(:exists?).with(request_id).and_return(true)
        allow(service).to receive(:find_blob).with(valid_id).and_return(existing_blob)
      end

      it "returns the existing blob without storing again" do
        result = service.store_blob(id: valid_id, data: valid_data, request_id: request_id)

        expect(result).to eq(existing_blob)
        expect(storage_strategy).not_to have_received(:store)
        expect(blob_repository).not_to have_received(:save)
      end
    end

    context "when the request is not idempotent" do
      let(:blob) { instance_double(Domain::Entities::Blob) }

      before do
        allow(idempotency_service).to receive(:exists?).with(request_id).and_return(false)
        allow(Domain::Entities::Blob).to receive(:new).and_return(blob)
        # These are already set up in the main before block as spies
        # allow(storage_strategy).to receive(:store).with(blob)
        # allow(blob_repository).to receive(:save).with(blob)
        allow(idempotency_service).to receive(:mark_as_processed).with(request_id, valid_id)
      end

      it "creates, stores, and saves the blob" do
        result = service.store_blob(id: valid_id, data: valid_data, request_id: request_id)

        expect(result).to eq(blob)
        expect(Domain::Entities::Blob).to have_received(:new).with(
          id: valid_id,
          data: valid_data,
          storage_type: storage_type
        )
        expect(storage_strategy).to have_received(:store).with(blob)
        expect(blob_repository).to have_received(:save).with(blob)
        expect(idempotency_service).to have_received(:mark_as_processed).with(request_id, valid_id)
      end

      context "when the data is not valid base64" do
        before do
          allow(Domain::Entities::Blob).to receive(:new).and_raise(ArgumentError.new("Invalid base64"))
        end

        it "raises an InvalidBlobDataError" do
          expect {
            service.store_blob(id: valid_id, data: "invalid-base64", request_id: request_id)
          }.to raise_error(Domain::Errors::InvalidBlobDataError)
        end
      end

      context "when there's an error storing the blob" do
        before do
          allow(storage_strategy).to receive(:store).and_raise(StandardError.new("Storage error"))
        end

        it "raises a BlobStorageError" do
          expect {
            service.store_blob(id: valid_id, data: valid_data, request_id: request_id)
          }.to raise_error(Domain::Errors::BlobStorageError)
        end
      end
    end
  end

  describe "#find_blob" do
    context "when the blob is in the cache" do
      let(:cached_blob) { instance_double(Domain::Entities::Blob) }

      before do
        allow(cache_service).to receive(:get).with(valid_id).and_return(cached_blob)
      end

      it "returns the cached blob" do
        result = service.find_blob(valid_id)

        expect(result).to eq(cached_blob)
        expect(blob_repository).not_to have_received(:find)
      end
    end

    context "when the blob is not in the cache" do
      let(:blob) { instance_double(Domain::Entities::Blob) }

      before do
        allow(cache_service).to receive(:get).with(valid_id).and_return(nil)
        allow(blob_repository).to receive(:find).with(valid_id).and_return(blob)
        allow(cache_service).to receive(:set).with(valid_id, blob)
      end

      it "finds the blob in the repository and caches it" do
        result = service.find_blob(valid_id)

        expect(result).to eq(blob)
        expect(blob_repository).to have_received(:find).with(valid_id)
        expect(cache_service).to have_received(:set).with(valid_id, blob)
      end

      context "when the blob is not found" do
        before do
          allow(blob_repository).to receive(:find).and_raise(Domain::Errors::BlobNotFoundError.new("Not found"))
        end

        it "raises a BlobNotFoundError" do
          expect {
            service.find_blob(valid_id)
          }.to raise_error(Domain::Errors::BlobNotFoundError)
        end
      end
    end
  end
end
