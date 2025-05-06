FactoryBot.define do
  factory :stored_blob, class: 'Infrastructure::Persistence::StoredBlob' do
    data { "MyString" }
    size { 1 }
    created_at { "2025-05-05 23:32:27" }
  end
end
