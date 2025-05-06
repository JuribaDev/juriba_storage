require 'rails_helper'
require_relative '../../../app/infrastructure/persistence/blob_tracker'

RSpec.describe Infrastructure::Repositories::BlobRepository do
  let(:storage_factory) { instance_double(Domain::Interfaces::StorageFactory) }
  let(:storage_strategy) { instance_double(Domain::Interfaces::BlobStorageStrategy) }
  let(:blob_id) { "123e4567-e89b-12d3-a456-426614174000" } # Valid UUID format
  let(:blob_size) { 100 }
  let(:storage_type) { "s3" }
  let(:created_at) { Time.new(2023, 1, 1).utc }

  subject(:repository) { described_class.new(storage_factory: storage_factory) }

  before do
    allow(storage_factory).to receive(:create).and_return(storage_strategy)
  end

  describe "#save" do
    let(:blob) do
      instance_double(
        Domain::Entities::Blob,
        id: blob_id,
        size: blob_size,
        storage_type: storage_type,
        created_at: created_at
      )
    end

    context "when the blob tracker doesn't exist" do
      it "creates a new blob tracker" do
        expect {
          repository.save(blob)
        }.to change(Infrastructure::Persistence::BlobTracker, :count).by(1)

        tracker = Infrastructure::Persistence::BlobTracker.find_by(id: blob_id)
        expect(tracker).not_to be_nil
        expect(tracker.blob_size).to eq(blob_size)
        expect(tracker.storage_type).to eq(storage_type)
        expect(tracker.created_at).to eq(created_at)
      end
    end

    context "when the blob tracker already exists" do
      before do
        Infrastructure::Persistence::BlobTracker.create!(
          id: blob_id,
          blob_id: "old-blob-id",
          blob_size: 50,
          storage_type: "database",
          created_at: Time.new(2022, 1, 1).utc
        )
      end

      it "updates the existing blob tracker" do
        expect {
          repository.save(blob)
        }.not_to change(Infrastructure::Persistence::BlobTracker, :count)

        tracker = Infrastructure::Persistence::BlobTracker.find_by(id: blob_id)
        expect(tracker.blob_size).to eq(blob_size)
        expect(tracker.storage_type).to eq(storage_type)
        expect(tracker.created_at).to eq(created_at)
      end
    end

    it "returns the blob" do
      result = repository.save(blob)
      expect(result).to eq(blob)
    end
  end

  describe "#find" do
    let(:blob_data) { Base64.strict_encode64("test data") }
    let(:blob_data_size) { Base64.decode64(blob_data).bytesize }

    before do
      # Create a blob tracker
      Infrastructure::Persistence::BlobTracker.create!(
        id: blob_id,
        blob_id: blob_id,
        blob_size: blob_size,
        storage_type: storage_type,
        created_at: created_at
      )

      # Mock the storage strategy
      allow(storage_strategy).to receive(:retrieve).with(blob_id).and_return({
        data: blob_data,
        size: blob_data_size,
        created_at: created_at
      })
    end

    it "retrieves the blob from the storage strategy" do
      blob = repository.find(blob_id)

      expect(blob).to be_a(Domain::Entities::Blob)
      # We expect the ID to remain as a standard UUID
      expect(blob.id).to eq(blob_id)
      expect(blob.id.length).to eq(36)
      expect(blob.data).to eq(blob_data)
      expect(blob.size).to eq(blob_data_size)
      expect(blob.created_at).to eq(created_at)
      expect(blob.storage_type).to eq(storage_type)

      expect(storage_factory).to have_received(:create)
      expect(storage_strategy).to have_received(:retrieve).with(blob_id)
    end

    context "when the blob tracker doesn't exist" do
      before do
        Infrastructure::Persistence::BlobTracker.delete_all
      end

      it "raises a BlobNotFoundError" do
        expect { repository.find(blob_id) }.to raise_error(Domain::Errors::BlobNotFoundError)
      end
    end

    context "when the storage strategy raises a BlobNotFoundError" do
      before do
        allow(storage_strategy).to receive(:retrieve).with(blob_id).and_raise(Domain::Errors::BlobNotFoundError.new("Not found"))
      end

      it "raises a BlobNotFoundError" do
        expect { repository.find(blob_id) }.to raise_error(Domain::Errors::BlobNotFoundError)
      end
    end
  end
end
