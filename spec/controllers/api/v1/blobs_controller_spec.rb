require 'rails_helper'

RSpec.describe Api::V1::BlobsController, type: :controller do
  let(:blob_service) { instance_double(Application::Services::BlobService) }
  let(:valid_id) { "a" * 26 }
  let(:valid_data) { Base64.strict_encode64("test data") }
  let(:request_id) { "request-123" }
  let(:blob) do
    instance_double(
      Domain::Entities::Blob,
      id: valid_id,
      data: valid_data,
      size: 100,
      created_at: Time.new(2023, 1, 1).utc,
      to_h: {
        id: valid_id,
        data: valid_data,
        size: "100",
        created_at: Time.new(2023, 1, 1).utc.iso8601
      }
    )
  end

  before do
    allow(controller).to receive(:blob_service_factory).and_return(blob_service)

    # Skip authentication for all tests
    allow(controller).to receive(:authenticate_request).and_return(true)
  end

  describe "POST #create" do
    context "with valid parameters" do
      before do
        allow(blob_service).to receive(:store_blob).and_return(blob)

        request.headers["Idempotency-Key"] = request_id
        post :create, params: { id: valid_id, data: valid_data }
      end

      it "returns a 201 Created status" do
        expect(response).to have_http_status(:created)
      end

      it "returns the blob data" do
        expect(JSON.parse(response.body)).to eq(blob.to_h.stringify_keys)
      end

      it "calls the blob service with the correct parameters" do
        expect(blob_service).to have_received(:store_blob).with(
          id: valid_id,
          data: valid_data,
          request_id: request_id
        )
      end
    end

    context "with invalid base64 data" do
      before do
        allow(blob_service).to receive(:store_blob).and_raise(Domain::Errors::InvalidBase64Error.new("Invalid Base64 encoding"))

        request.headers["Idempotency-Key"] = request_id
        post :create, params: { id: valid_id, data: "invalid-base64" }
      end

      it "returns a 400 Bad Request status" do
        expect(response).to have_http_status(:bad_request)
      end

      it "returns an error message" do
        expect(JSON.parse(response.body)).to eq({ "error" => "Invalid Base64 encoding" })
      end
    end

    context "with invalid blob data" do
      before do
        allow(blob_service).to receive(:store_blob).and_raise(Domain::Errors::InvalidBlobDataError.new("Invalid blob data"))

        request.headers["Idempotency-Key"] = request_id
        post :create, params: { id: valid_id, data: valid_data }
      end

      it "returns a 400 Bad Request status" do
        expect(response).to have_http_status(:bad_request)
      end

      it "returns an error message" do
        expect(JSON.parse(response.body)).to eq({ "error" => "Invalid blob data" })
      end
    end

    context "when there's a storage error" do
      before do
        allow(blob_service).to receive(:store_blob).and_raise(Domain::Errors::BlobStorageError.new("Storage error"))

        request.headers["Idempotency-Key"] = request_id
        post :create, params: { id: valid_id, data: valid_data }
      end

      it "returns a 500 Internal Server Error status" do
        expect(response).to have_http_status(:internal_server_error)
      end

      it "returns an error message" do
        expect(JSON.parse(response.body)).to eq({ "error" => "Storage error" })
      end
    end
  end

  describe "GET #show" do
    context "when the blob exists" do
      before do
        allow(blob_service).to receive(:find_blob).with(valid_id).and_return(blob)

        get :show, params: { id: valid_id }
      end

      it "returns a 200 OK status" do
        expect(response).to have_http_status(:ok)
      end

      it "returns the blob data" do
        expect(JSON.parse(response.body)).to eq(blob.to_h.stringify_keys)
      end
    end

    context "when the blob doesn't exist" do
      before do
        allow(blob_service).to receive(:find_blob).with(valid_id).and_raise(Domain::Errors::BlobNotFoundError.new("Blob not found"))

        get :show, params: { id: valid_id }
      end

      it "returns a 404 Not Found status" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns an error message" do
        expect(JSON.parse(response.body)).to eq({ "error" => "Blob not found" })
      end
    end
  end
end
