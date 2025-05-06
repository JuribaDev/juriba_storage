require 'rails_helper'

RSpec.describe Infrastructure::Factories::StorageFactory do
  let(:config_service) { instance_double(Domain::Interfaces::ConfigurationService) }

  subject(:factory) { described_class.new(config_service: config_service) }

  describe "#create" do
    context "when storage_type is s3" do
      before do
        allow(config_service).to receive(:storage_type).and_return("s3")
        allow(config_service).to receive(:s3_config).and_return({
          access_key_id: "test_key",
          secret_access_key: "test_secret",
          bucket: "test_bucket"
        })
      end

      it "creates an S3Storage instance" do
        storage = factory.create

        expect(storage).to be_a(Infrastructure::Strategies::S3Storage)
      end
    end

    context "when storage_type is database" do
      before do
        allow(config_service).to receive(:storage_type).and_return("database")
      end

      it "creates a DatabaseStorage instance" do
        storage = factory.create

        expect(storage).to be_a(Infrastructure::Strategies::DatabaseStorage)
      end
    end

    context "when storage_type is local" do
      before do
        allow(config_service).to receive(:storage_type).and_return("local")
        allow(config_service).to receive(:local_storage_config).and_return({
          path: "/tmp/storage"
        })
      end

      it "creates a LocalStorage instance" do
        storage = factory.create

        expect(storage).to be_a(Infrastructure::Strategies::LocalStorage)
      end
    end

    context "when storage_type is unsupported" do
      before do
        allow(config_service).to receive(:storage_type).and_return("unsupported")
      end

      it "raises an ArgumentError" do
        expect { factory.create }.to raise_error(ArgumentError, "Unsupported storage type: unsupported")
      end
    end

    context "when storage_type has uppercase letters" do
      before do
        allow(config_service).to receive(:storage_type).and_return("S3")
        allow(config_service).to receive(:s3_config).and_return({
          access_key_id: "test_key",
          secret_access_key: "test_secret",
          bucket: "test_bucket"
        })
      end

      it "handles the case insensitively" do
        storage = factory.create

        expect(storage).to be_a(Infrastructure::Strategies::S3Storage)
      end
    end
  end
end
