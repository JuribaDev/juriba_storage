module Infrastructure
  module Persistence
    class StoredBlob < ApplicationRecord
      validates :id, presence: true, uniqueness: true
      validates :data, presence: true

      before_save :set_created_at

      private

      def set_created_at
        self.created_at ||= Time.current.utc
      end
    end
  end
end
