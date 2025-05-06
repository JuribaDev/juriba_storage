require 'spec_helper'
require 'base64'
require 'time'
require 'uri'
require 'net/http'
require 'openssl'

# Load necessary domain interfaces
require_relative '../../../app/domain/interfaces/blob_storage_strategy'
require_relative '../../../app/domain/errors'

# Load the implementation
require_relative '../../../app/infrastructure/strategies/s3_storage'

RSpec.describe Infrastructure::Strategies::S3Storage do
  let(:config_service) { double('Domain::Interfaces::ConfigurationService') }
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
    double(
      'Domain::Entities::Blob',
      id: blob_id,
      data: blob_data
    )
  end

  before do
    allow(config_service).to receive(:s3_config).and_return(s3_config)

    # Mock HTTP requests
    @http_mock = double('Net::HTTP')
    allow(Net::HTTP).to receive(:new).and_return(@http_mock)
    allow(@http_mock).to receive(:use_ssl=)
    allow(@http_mock).to receive(:verify_mode=)
    allow(@http_mock).to receive(:start).and_yield(@http_mock)

    # Mock Rails.env.test? for non-Rails environment
    if defined?(Rails)
      # Save the original Rails.env
      @original_rails_env = Rails.env
      # Override Rails.env to return a non-test environment
      allow(Rails).to receive(:env).and_return(OpenStruct.new(test?: false))
    else
      module Rails
        def self.env
          OpenStruct.new(test?: false)
        end
      end
    end
  end

  after do
    # Clean up the Rails mock if we created it
    if defined?(Rails) && !defined?(::Rails.application)
      Object.send(:remove_const, :Rails)
    elsif defined?(@original_rails_env)
      # Restore the original Rails.env
      allow(Rails).to receive(:env).and_return(@original_rails_env)
    end
  end

  subject(:storage) { described_class.new(config_service: config_service) }

  describe "#initialize" do
    it "creates a bucket if it doesn't exist" do
      # Mock the bucket creation request - do this BEFORE creating the storage instance
      bucket_request = double('Net::HTTP::Put')
      allow(Net::HTTP::Put).to receive(:new).with("/test-bucket").and_return(bucket_request)
      allow(bucket_request).to receive(:[]=)
      allow(bucket_request).to receive(:body=)
      allow(bucket_request).to receive(:body).and_return("")
      allow(bucket_request).to receive(:path).and_return("/test-bucket")
      allow(bucket_request).to receive(:method).and_return("PUT")
      allow(bucket_request).to receive(:each_header)
      allow(bucket_request).to receive(:each_capitalized)
      allow(bucket_request).to receive(:instance_variables).and_return([])

      # Mock successful response
      response = double('Net::HTTPSuccess')
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      allow(response).to receive(:code).and_return("200")
      allow(@http_mock).to receive(:request).with(bucket_request).and_return(response)

      # Initialize the storage - this should trigger bucket creation
      described_class.new(config_service: config_service)

      # Verify the bucket creation request was made
      expect(Net::HTTP::Put).to have_received(:new).with("/test-bucket")
      expect(@http_mock).to have_received(:request).with(bucket_request)
    end
  end
end
