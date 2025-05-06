module Api
  module V1
    class BlobsController < ApplicationController
      skip_before_action :authenticate_request, only: [ :generate_uuid ]

      # POST /v1/blobs
      def create
        blob_service = blob_service_factory

        begin
          blob = blob_service.store_blob(
            id: params[:id],
            data: params[:data],
            request_id: request.headers["Idempotency-Key"]
          )

          render json: blob.to_h, status: :created
        rescue Domain::Errors::InvalidBase64Error, Domain::Errors::InvalidBlobDataError => e
          render json: { error: e.message }, status: :bad_request
        rescue Domain::Errors::BlobStorageError => e
          render json: { error: e.message }, status: :internal_server_error
        end
      end

      # GET /v1/blobs/:id
      def show
        blob_service = blob_service_factory

        begin
          blob = blob_service.find_blob(params[:id])
          render json: blob.to_h
        rescue Domain::Errors::BlobNotFoundError => e
          render json: { error: e.message }, status: :not_found
        end
      end

      # GET /v1/blobs/generate_uuid
      def generate_uuid
        uuid = SecureRandom.uuid
        render json: { uuid: uuid }, status: :ok
      end

      private

      def blob_service_factory
        Infrastructure::Container.resolve(:blob_service)
      end
    end
  end
end
