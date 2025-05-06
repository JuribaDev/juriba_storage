require 'rails_helper'
require_relative '../../../app/infrastructure/persistence/stored_blob'

RSpec.describe Infrastructure::Strategies::DatabaseStorage, requires_db: false do
  let(:blob_id) { "test-blob-id" }
  let(:blob_data) { Base64.strict_encode64("test data") }
  let(:blob) do
    instance_double(
      Domain::Entities::Blob,
      id: blob_id,
      data: blob_data
    )
  end

  subject(:storage) { described_class.new }

  describe "#store" do
    it "stores the blob data in the database" do
      # Mock the ActiveRecord operations
      stored_blob = instance_double(Infrastructure::Persistence::StoredBlob)
      allow(Infrastructure::Persistence::StoredBlob).to receive(:find_or_initialize_by).with(id: blob_id).and_return(stored_blob)
      allow(stored_blob).to receive(:data=)
      allow(stored_blob).to receive(:save!)

      storage.store(blob)

      expect(Infrastructure::Persistence::StoredBlob).to have_received(:find_or_initialize_by).with(id: blob_id)
      expect(stored_blob).to have_received(:data=).with(Base64.decode64(blob_data))
      expect(stored_blob).to have_received(:save!)
    end
  end

  describe "#retrieve" do
    context "when the blob exists" do
      let(:created_at) { Time.new(2023, 1, 1).utc }

      it "retrieves the blob data from the database" do
        # Mock the ActiveRecord operations
        stored_blob = instance_double(Infrastructure::Persistence::StoredBlob)
        allow(Infrastructure::Persistence::StoredBlob).to receive(:find_by).with(id: blob_id).and_return(stored_blob)
        allow(stored_blob).to receive(:data).and_return(Base64.decode64(blob_data))
        allow(stored_blob).to receive(:created_at).and_return(created_at)

        result = storage.retrieve(blob_id)

        expect(result[:data]).to eq(blob_data)
        expect(result[:size]).to eq(Base64.decode64(blob_data).bytesize)
        expect(result[:created_at]).to eq(created_at)
      end
    end

    context "when the blob does not exist" do
      it "raises a BlobNotFoundError" do
        allow(Infrastructure::Persistence::StoredBlob).to receive(:find_by).with(id: blob_id).and_return(nil)

        expect { storage.retrieve(blob_id) }.to raise_error(Domain::Errors::BlobNotFoundError)
      end
    end
  end
end
