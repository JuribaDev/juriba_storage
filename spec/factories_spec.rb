require 'rails_helper'
require_relative '../app/infrastructure/persistence/blob_tracker'
require_relative '../app/infrastructure/persistence/stored_blob'

RSpec.describe "Factories", requires_db: false do
  it "creates a blob tracker" do
    tracker = FactoryBot.build_stubbed(:blob_tracker)
    expect(tracker).to be_a(Infrastructure::Persistence::BlobTracker)
  end

  it "creates a stored blob" do
    blob = FactoryBot.build_stubbed(:stored_blob)
    expect(blob).to be_a(Infrastructure::Persistence::StoredBlob)
  end
end
