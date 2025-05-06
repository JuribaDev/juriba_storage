require 'rails_helper'

RSpec.describe Infrastructure::Strategies::LocalStorage, requires_db: false do
  let(:config_service) { instance_double(Domain::Interfaces::ConfigurationService) }
  let(:storage_path) { Rails.root.join('tmp', 'test_storage').to_s }
  let(:local_storage_config) do
    {
      path: storage_path
    }
  end

  let(:blob_id) { "test-blob-id" }
  let(:blob_data) { Base64.strict_encode64("test data") }
  let(:blob) do
    instance_double(
      Domain::Entities::Blob,
      id: blob_id,
      data: blob_data,
      created_at: Time.new(2023, 1, 1).utc
    )
  end

  before do
    allow(config_service).to receive(:local_storage_config).and_return(local_storage_config)

    # Clean up test directory
    FileUtils.rm_rf(storage_path)
  end

  after do
    # Clean up test directory
    FileUtils.rm_rf(storage_path)
  end

  subject(:storage) { described_class.new(config_service: config_service) }

  describe "#initialize" do
    it "creates the storage directory if it doesn't exist" do
      expect(Dir.exist?(storage_path)).to be false
      storage
      expect(Dir.exist?(storage_path)).to be true
    end
  end

  describe "#store" do
    it "stores the blob data in the filesystem" do
      storage.store(blob)

      # Check that the data file exists
      data_path = File.join(storage_path, blob_id)
      expect(File.exist?(data_path)).to be true

      # Check that the metadata file exists
      meta_path = "#{data_path}.meta"
      expect(File.exist?(meta_path)).to be true

      # Check the content of the data file
      stored_data = File.binread(data_path)
      expect(stored_data).to eq(Base64.decode64(blob_data))

      # Check the content of the metadata file
      metadata = JSON.parse(File.read(meta_path))
      expect(metadata["created_at"]).to eq(blob.created_at.iso8601)
    end
  end

  describe "#retrieve" do
    context "when the blob exists" do
      before do
        # Create the data file
        FileUtils.mkdir_p(storage_path)
        File.binwrite(File.join(storage_path, blob_id), Base64.decode64(blob_data))

        # Create the metadata file
        File.write("#{File.join(storage_path, blob_id)}.meta", {
          created_at: Time.new(2023, 1, 1).utc.iso8601
        }.to_json)
      end

      it "retrieves the blob data from the filesystem" do
        result = storage.retrieve(blob_id)

        expect(result[:data]).to eq(blob_data)
        expect(result[:size]).to eq(Base64.decode64(blob_data).bytesize)
        expect(result[:created_at]).to eq(Time.new(2023, 1, 1).utc)
      end
    end

    context "when the blob does not exist" do
      it "raises a BlobNotFoundError" do
        expect { storage.retrieve(blob_id) }.to raise_error(Domain::Errors::BlobNotFoundError)
      end
    end

    context "when the metadata file does not exist" do
      before do
        # Create only the data file
        FileUtils.mkdir_p(storage_path)
        File.binwrite(File.join(storage_path, blob_id), Base64.decode64(blob_data))
      end

      it "raises a BlobNotFoundError" do
        expect { storage.retrieve(blob_id) }.to raise_error(Domain::Errors::BlobNotFoundError)
      end
    end
  end
end
