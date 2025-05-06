module Infrastructure
  module Persistence
    class BlobTracker < ApplicationRecord
      self.primary_key = :id

      validates :id, presence: true, uniqueness: true
      validates :blob_id, presence: true, uniqueness: true
      validates :blob_size, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
      validates :storage_type, presence: true
    end
  end
end
