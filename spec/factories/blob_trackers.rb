FactoryBot.define do
  factory :blob_tracker, class: 'Infrastructure::Persistence::BlobTracker' do
    blob_id { "MyString" }
    blob_size { 1 }
    storage_type { "MyString" }
    created_at { "2025-05-05 23:33:23" }
  end
end
