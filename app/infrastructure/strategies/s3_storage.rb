require "uri"
require "net/http"
require "openssl"
require "time"
require "base64"

module Infrastructure
  module Strategies
    class S3Storage < Domain::Interfaces::BlobStorageStrategy
      def initialize(config_service:)
        @config = config_service.s3_config
        @access_key = @config[:access_key_id]
        @secret_key = @config[:secret_access_key]
        @endpoint = @config[:endpoint]
        @region = @config[:region]
        @bucket = @config[:bucket]
        @service = "s3"

        # Skip bucket creation in test environment
        # Check if Rails is defined and if we're in test environment
        create_bucket unless defined?(Rails) && Rails.env.test?
      end

      def store(blob)
        object_key = blob.id
        body = Base64.decode64(blob.data)

        headers = {
          "Content-Type" => "application/octet-stream",
          "Content-Length" => body.bytesize.to_s
        }

        uri = URI.parse("#{@endpoint}/#{@bucket}/#{object_key}")
        request = Net::HTTP::Put.new("/#{@bucket}/#{object_key}", headers)
        request.body = body

        sign_request(request, body)
        response = send_request(uri, request)

        unless response.is_a?(Net::HTTPSuccess)
          raise "Failed to store blob: #{response.code} - #{response.message} - #{response.body}"
        end

        true
      end

      def retrieve(blob_id)
        uri = URI.parse("#{@endpoint}/#{@bucket}/#{blob_id}")
        request = Net::HTTP::Get.new("/#{@bucket}/#{blob_id}")

        sign_request(request)
        response = send_request(uri, request)

        unless response.is_a?(Net::HTTPSuccess)
          raise Domain::Errors::BlobNotFoundError, "Blob not found with ID: #{blob_id}"
        end

        data = response.body
        last_modified = response["Last-Modified"] ? Time.parse(response["Last-Modified"]) : Time.now

        {
          data: Base64.strict_encode64(data),
          size: data.bytesize,
          created_at: last_modified
        }
      end

      private

      def create_bucket
        uri = URI.parse("#{@endpoint}/#{@bucket}")
        request = Net::HTTP::Put.new("/#{@bucket}")
        sign_request(request, request.body || "")
        response = send_request(uri, request)

        # 200 OK, or 409 Conflict (bucket already exists)
        return true if response.is_a?(Net::HTTPSuccess) || response.code == "409"

        # Other errors
        raise "Failed to create bucket: #{response.code} - #{response.message}: #{response.body}"
      end

      def send_request(uri, request)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"

        # For MinIO in development environments, you might want to skip certificate verification
        if uri.scheme == "https" && @config[:skip_ssl_verify]
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        http.start { |http| http.request(request) }
      end

      def sign_request(request, payload = "")
        # Current datetime for request signing
        now = Time.now.utc
        amz_date = now.strftime("%Y%m%dT%H%M%SZ")
        date_stamp = now.strftime("%Y%m%d")

        # Add required headers
        request["Host"] = URI.parse(@endpoint).host
        request["X-Amz-Date"] = amz_date
        request["X-Amz-Content-Sha256"] = hex_encode_sha256(payload)

        # Task 1: Create canonical request
        canonical_uri = URI.parse("#{@endpoint}#{request.path}").path
        canonical_uri = "/" if canonical_uri.empty?

        canonical_querystring = ""

        canonical_headers = ""
        signed_headers = []

        # Collect and sort headers
        headers_to_sign = {}
        # Handle both each_header and each_capitalized methods for compatibility
        if request.respond_to?(:each_header)
          request.each_header do |header, value|
            header_name = header.downcase
            headers_to_sign[header_name] = value.strip
          end
        elsif request.respond_to?(:each_capitalized)
          request.each_capitalized do |header, value|
            header_name = header.downcase
            headers_to_sign[header_name] = value.strip
          end
        else
          # Fallback for test doubles
          request.instance_variables.each do |var|
            if var.to_s.start_with?("@")
              header = var.to_s[1..-1] # Remove @ prefix
              value = request.instance_variable_get(var)
              if header != "body" && header != "path" && !header.start_with?("env_")
                header_name = header.downcase
                headers_to_sign[header_name] = value.to_s.strip
              end
            end
          end
        end

        # Ensure host header is included
        headers_to_sign["host"] = URI.parse(@endpoint).host unless headers_to_sign.key?("host")

        # Build canonical headers string
        headers_to_sign.keys.sort.each do |header_name|
          canonical_headers += "#{header_name}:#{headers_to_sign[header_name]}\n"
          signed_headers << header_name
        end

        signed_headers_list = signed_headers.sort.join(";")
        payload_hash = hex_encode_sha256(payload)

        canonical_request = [
          request.method,
          canonical_uri,
          canonical_querystring,
          canonical_headers,
          signed_headers_list,
          payload_hash
        ].join("\n")

        # Task 2: Create string to sign
        credential_scope = "#{date_stamp}/#{@region}/#{@service}/aws4_request"

        string_to_sign = [
          "AWS4-HMAC-SHA256",
          amz_date,
          credential_scope,
          hex_encode_sha256(canonical_request)
        ].join("\n")

        # Task 3: Calculate signature
        k_date = hmac_sha256("AWS4#{@secret_key}", date_stamp)
        k_region = hmac_sha256(k_date, @region)
        k_service = hmac_sha256(k_region, @service)
        k_signing = hmac_sha256(k_service, "aws4_request")
        signature = hex_encode_hmac_sha256(k_signing, string_to_sign)

        # Task 4: Add signature to request
        auth_header = "AWS4-HMAC-SHA256 " \
          "Credential=#{@access_key}/#{credential_scope}, " \
          "SignedHeaders=#{signed_headers_list}, " \
          "Signature=#{signature}"

        request["Authorization"] = auth_header
      end

      def hmac_sha256(key, value)
        OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha256"), key, value)
      end

      def hex_encode_hmac_sha256(key, value)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), key, value)
      end

      def hex_encode_sha256(value)
        OpenSSL::Digest::SHA256.hexdigest(value)
      end
    end
  end
end
