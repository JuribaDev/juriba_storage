module Domain
  module Errors
    class BlobStorageError < StandardError; end
    class BlobNotFoundError < StandardError; end
    class InvalidBase64Error < StandardError; end
    class InvalidBlobDataError < StandardError; end
    class AuthenticationError < StandardError; end
  end
end
