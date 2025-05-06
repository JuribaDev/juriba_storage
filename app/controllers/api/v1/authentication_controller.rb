module Api
  module V1
    class AuthenticationController < ApplicationController
      # Skip the global authentication filter for these public actions
      skip_before_action :authenticate_request, only: :login

      # POST /api/v1/login
      def login
        username = params.require(:username)
        password = params.require(:password)

        user = User.find_by(username: username)
        new_user_created = false

        if user.nil?
          # User doesn't exist, create them
          Rails.logger.warn("Auto-creating user with username: #{username}")
          # Security concern: Auto-creating users without email verification
          user = User.new(username: username, password: password)
          unless user.save
            Rails.logger.error("Failed to create user: #{user.errors.full_messages}")
            render json: { errors: user.errors.full_messages }, status: :unprocessable_content
            return
          end
          new_user_created = true
        elsif !user.authenticate(password)
          Rails.logger.warn("Failed login attempt for user: #{username}")
          render json: { error: "Invalid credentials" }, status: :unauthorized
          return
        end

        issue_tokens_and_respond(user, new_user_created)
      end

      private

      def issue_tokens_and_respond(user, is_new_user)
        # Issue Access Token
        begin
          access_payload = { user_id: user.id }
          access_token = JsonWebToken.encode_access_token(access_payload)
          access_token_expires_at = Time.zone.now + 10.minutes

          response_status = is_new_user ? :created : :ok
          render json: {
            access_token: access_token,
            access_token_expires_at: access_token_expires_at.iso8601,
            username: user.username
          }, status: response_status
        rescue StandardError => e
          Rails.logger.error("Failed to process login. Please try again #{user.id}: #{e.message}")
          render json: { error: "Failed to process login. Please try again." }, status: :internal_server_error
        end
      end
    end
  end
end
