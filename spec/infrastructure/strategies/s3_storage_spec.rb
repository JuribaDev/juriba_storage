require 'rails_helper'

RSpec.describe Infrastructure::Strategies::S3Storage, requires_db: false do
  let(:config_service) { instance_double(Domain::Interfaces::ConfigurationService) }
  let(:s3_config) do
    {
      access_key_id: 'test_key',
      secret_access_key: 'test_secret',
      endpoint: 'http://localhost:9000',
      region: 'us-east-1',
      bucket: 'test-bucket',
      force_path_style: true,
      skip_ssl_verify: true
    }
  end

  let(:blob_id) { "test-blob-id" }
  let(:blob_data) { Base64.strict_encode64("test data") }
  let(:blob) do
    instance_double(
      Domain::Entities::Blob,
      id: blob_id,
      data: blob_data
    )
  end

  before do
    allow(config_service).to receive(:s3_config).and_return(s3_config)

    # Mock HTTP requests
    @http_mock = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:new).and_return(@http_mock)
    allow(@http_mock).to receive(:use_ssl=)
    allow(@http_mock).to receive(:verify_mode=)
    allow(@http_mock).to receive(:start).and_yield(@http_mock)
  end

  # Stub Net::HTTP::Put.new before subject is initialized
  before do
    allow(Net::HTTP::Put).to receive(:new).and_call_original
  end

  subject(:storage) { described_class.new(config_service: config_service) }

  describe "#initialize" do
    it "skips bucket creation in test environment" do
      # Since we're in a Rails test environment, bucket creation should be skipped
      # Initialize the storage
      storage

      # Verify the bucket creation request was NOT made
      expect(Net::HTTP::Put).not_to have_received(:new).with("/test-bucket")
    end

    # No need to test bucket creation scenarios in test environment
  end

  describe "#store" do
    # No need to mock bucket creation as it's skipped in test environment

    it "stores the blob data in S3" do
      # Mock the put object request
      put_request = instance_double(Net::HTTP::Put)
      allow(Net::HTTP::Put).to receive(:new).with(any_args) do |path, headers|
        if path == "/test-bucket/#{blob_id}"
          put_request
        else
          original_new = Net::HTTP::Put.method(:new).super_method
          original_new.call(path, headers)
        end
      end
      allow(put_request).to receive(:[]=)
      allow(put_request).to receive(:body=)
      allow(put_request).to receive(:body).and_return(Base64.decode64(blob_data))
      allow(put_request).to receive(:path).and_return("/test-bucket/#{blob_id}")
      allow(put_request).to receive(:method).and_return("PUT")
      allow(put_request).to receive(:each_header)
      allow(put_request).to receive(:each_capitalized)
      allow(put_request).to receive(:instance_variables).and_return([])

      # Mock successful response
      response = instance_double(Net::HTTPSuccess)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(@http_mock).to receive(:request).with(put_request).and_return(response)

      # Store the blob
      storage.store(blob)

      # Verify the put object request was made
      expect(Net::HTTP::Put).to have_received(:new).with("/test-bucket/#{blob_id}", any_args)
      expect(@http_mock).to have_received(:request).with(put_request)
    end

    context "when the request fails" do
      it "raises an error" do
        # Mock the put object request
        put_request = instance_double(Net::HTTP::Put)
        allow(Net::HTTP::Put).to receive(:new).with(any_args) do |path, headers|
          if path == "/test-bucket/#{blob_id}"
            put_request
          else
            original_new = Net::HTTP::Put.method(:new).super_method
            original_new.call(path, headers)
          end
        end
        allow(put_request).to receive(:[]=)
        allow(put_request).to receive(:body=)
        allow(put_request).to receive(:body).and_return(Base64.decode64(blob_data))
        allow(put_request).to receive(:path).and_return("/test-bucket/#{blob_id}")
        allow(put_request).to receive(:method).and_return("PUT")
        allow(put_request).to receive(:each_header)
        allow(put_request).to receive(:each_capitalized)
        allow(put_request).to receive(:instance_variables).and_return([])

        # Mock error response
        response = instance_double(Net::HTTPBadRequest)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(response).to receive(:code).and_return("400")
        allow(response).to receive(:message).and_return("Bad Request")
        allow(response).to receive(:body).and_return("Error details")
        allow(@http_mock).to receive(:request).with(put_request).and_return(response)

        # Attempt to store the blob
        expect { storage.store(blob) }.to raise_error(/Failed to store blob/)
      end
    end
  end

  describe "#retrieve" do
    # No need to mock bucket creation as it's skipped in test environment

    it "retrieves the blob data from S3" do
      # Mock the get object request
      get_request = instance_double(Net::HTTP::Get)
      allow(Net::HTTP::Get).to receive(:new).with(any_args) do |path, headers|
        if path == "/test-bucket/#{blob_id}"
          get_request
        else
          original_new = Net::HTTP::Get.method(:new).super_method
          original_new.call(path, headers)
        end
      end
      allow(get_request).to receive(:[]=)
      allow(get_request).to receive(:path).and_return("/test-bucket/#{blob_id}")
      allow(get_request).to receive(:method).and_return("GET")
      allow(get_request).to receive(:each_header)
      allow(get_request).to receive(:each_capitalized)
      allow(get_request).to receive(:instance_variables).and_return([])

      # Mock successful response
      response = instance_double(Net::HTTPSuccess)
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(response).to receive(:body).and_return("test data")
      allow(response).to receive(:[]).with("Last-Modified").and_return("Wed, 21 Oct 2015 07:28:00 GMT")
      allow(@http_mock).to receive(:request).with(get_request).and_return(response)

      # Retrieve the blob
      result = storage.retrieve(blob_id)

      # Verify the get object request was made
      expect(Net::HTTP::Get).to have_received(:new).with("/test-bucket/#{blob_id}", any_args)
      expect(@http_mock).to have_received(:request).with(get_request)

      # Verify the result
      expect(result[:data]).to eq(Base64.strict_encode64("test data"))
      expect(result[:size]).to eq("test data".bytesize)
      expect(result[:created_at]).to eq(Time.parse("Wed, 21 Oct 2015 07:28:00 GMT"))
    end

    context "when the blob is not found" do
      it "raises a BlobNotFoundError" do
        # Mock the get object request
        get_request = instance_double(Net::HTTP::Get)
        allow(Net::HTTP::Get).to receive(:new).with(any_args) do |path, headers|
          if path == "/test-bucket/#{blob_id}"
            get_request
          else
            original_new = Net::HTTP::Get.method(:new).super_method
            original_new.call(path, headers)
          end
        end
        allow(get_request).to receive(:[]=)
        allow(get_request).to receive(:path).and_return("/test-bucket/#{blob_id}")
        allow(get_request).to receive(:method).and_return("GET")
        allow(get_request).to receive(:each_header)
        allow(get_request).to receive(:each_capitalized)
        allow(get_request).to receive(:instance_variables).and_return([])

        # Mock not found response
        response = instance_double(Net::HTTPNotFound)
        allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(response).to receive(:code).and_return("404")
        allow(@http_mock).to receive(:request).with(get_request).and_return(response)

        # Attempt to retrieve the blob
        expect { storage.retrieve(blob_id) }.to raise_error(Domain::Errors::BlobNotFoundError)
      end
    end
  end
end
