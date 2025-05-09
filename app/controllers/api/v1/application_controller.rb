module Api
  module V1
    class ApplicationController < ActionController::API
      before_action :authenticate_request

      private

      attr_reader :current_user

      def authenticate_request
        header = request.headers["Authorization"]
        token = header.split(" ").last if header&.start_with?("Bearer ")

        unless token
          render json: { errors: [ "Authorization header missing or invalid format" ] }, status: :unauthorized
          return
        end

        begin
          @decoded = JsonWebToken.decode_access_token(token)
          @current_user = User.find(@decoded[:user_id])
        rescue ActiveRecord::RecordNotFound => e
          Rails.logger.error("Authentication Error: User not found for token")
          Rails.logger.error("Error details: #{e.message}")
          Rails.logger.error("Backtrace: #{e.backtrace[0..3].join("\n")}")
          render json: { errors: [ "User associated with token not found" ] }, status: :unauthorized
        rescue JWT::ExpiredSignature => e
          Rails.logger.error("Authentication Error: #{e.message}\n#{e.backtrace.join("\n")}")
          render json: { errors: [ e.message ] }, status: :unauthorized
        rescue JWT::DecodeError => e
          Rails.logger.error("Authentication Error: #{e.message}\n#{e.backtrace.join("\n")}")
          render json: { errors: [ e.message ] }, status: :unauthorized
        rescue => e
          Rails.logger.error("Authentication Error: #{e.message}\n#{e.backtrace.join("\n")}")
          render json: { errors: [ "Authentication failed due to an unexpected error" ] }, status: :internal_server_error
        end
      end
    end
  end
end
