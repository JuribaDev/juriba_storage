require "jwt"

module JsonWebToken
  ACCESS_SECRET_KEY = Rails.application.credentials.secret_key_base || "dev_access_secret"
  ALGORITHM_TYPE = "HS256"

  # Encode Access Token
  def self.encode_access_token(payload)
    payload[:exp] = 10.minutes.from_now.to_i
    JWT.encode(payload, ACCESS_SECRET_KEY, ALGORITHM_TYPE)
  end

  # Decode Access Token
  def self.decode_access_token(token)
    begin
      decoded = JWT.decode(token, ACCESS_SECRET_KEY, true, algorithm: ALGORITHM_TYPE, verify_expiration: true)
      HashWithIndifferentAccess.new(decoded[0])
    rescue JWT::ExpiredSignature
      raise JWT::ExpiredSignature, "Access token has expired"
    rescue JWT::VerificationError, JWT::DecodeError => e
      Rails.logger.error("JWT Access Decode Error: #{e.message}")
      raise JWT::DecodeError, "Invalid access token: #{e.message}"
    end
  end
end
