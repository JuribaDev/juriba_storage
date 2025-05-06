require 'spec_helper'
require 'base64'
require 'time'
require 'logger'

# Mock Rails.logger
module Rails
  def self.logger
    @logger ||= Logger.new(IO::NULL)
  end
end

# Mock Time.current
class Time
  def self.current
    Time.now
  end
end

# Load the Blob class
require_relative '../../../app/domain/entities/blob'

RSpec.describe Domain::Entities::Blob do
  let(:valid_id) { "123e4567-e89b-12d3-a456-426614174000" } # Valid 36-character UUID
  let(:another_valid_uuid) { "123e4567-e89b-12d3-a456-426614174001" } # Another valid UUID
  let(:valid_data) { Base64.strict_encode64("test data") }
  let(:storage_type) { "s3" }

  describe "#initialize" do
    context "with valid parameters" do
      it "creates a blob with the provided attributes" do
        blob = described_class.new(
          id: valid_id,
          data: valid_data,
          storage_type: storage_type
        )

        expect(blob.id).to eq(valid_id)
        expect(blob.data).to eq(valid_data)
        expect(blob.storage_type).to eq(storage_type)
        expect(blob.size).to be_a(Integer)
        expect(blob.created_at).to be_a(Time)
      end

      it "calculates the size from the base64 data" do
        blob = described_class.new(
          id: valid_id,
          data: valid_data,
          storage_type: storage_type
        )

        expected_size = Base64.decode64(valid_data).bytesize
        expect(blob.size).to eq(expected_size)
      end

      it "uses the provided size if given" do
        custom_size = 1000
        blob = described_class.new(
          id: valid_id,
          data: valid_data,
          size: custom_size,
          storage_type: storage_type
        )

        expect(blob.size).to eq(custom_size)
      end

      it "uses the provided created_at if given" do
        custom_time = Time.new(2023, 1, 1).utc
        blob = described_class.new(
          id: valid_id,
          data: valid_data,
          created_at: custom_time,
          storage_type: storage_type
        )

        expect(blob.created_at).to eq(custom_time)
      end

      it "preserves the UUID format" do
        blob = described_class.new(
          id: valid_id,
          data: valid_data,
          storage_type: storage_type
        )

        expect(blob.id.length).to eq(36)
        expect(blob.id).to eq(valid_id)
      end

      it "accepts different valid UUIDs" do
        blob1 = described_class.new(
          id: valid_id,
          data: valid_data,
          storage_type: storage_type
        )

        blob2 = described_class.new(
          id: another_valid_uuid,
          data: valid_data,
          storage_type: storage_type
        )

        expect(blob1.id).to eq(valid_id)
        expect(blob2.id).to eq(another_valid_uuid)
      end
    end

    context "with invalid parameters" do
      it "raises an error when id is nil" do
        expect {
          described_class.new(
            id: nil,
            data: valid_data,
            storage_type: storage_type
          )
        }.to raise_error(ArgumentError, "Blob ID cannot be blank")
      end

      it "raises an error when id is empty" do
        expect {
          described_class.new(
            id: "",
            data: valid_data,
            storage_type: storage_type
          )
        }.to raise_error(ArgumentError, "Blob ID cannot be blank")
      end

      it "raises an error when data is nil" do
        expect {
          described_class.new(
            id: valid_id,
            data: nil,
            storage_type: storage_type
          )
        }.to raise_error(ArgumentError, "Blob data cannot be blank")
      end

      it "raises an error when data is empty" do
        expect {
          described_class.new(
            id: valid_id,
            data: "",
            storage_type: storage_type
          )
        }.to raise_error(ArgumentError, "Blob data cannot be blank")
      end

      it "raises an error when data is not valid base64" do
        expect {
          described_class.new(
            id: valid_id,
            data: "not-base64!",
            storage_type: storage_type
          )
        }.to raise_error(ArgumentError, /invalid base64|Blob data must be Base64 encoded/)
      end
    end
  end

  # The transform_uuid_if_needed method has been removed as we now use standard 36-character UUIDs

  describe "#to_h" do
    it "returns a hash representation of the blob" do
      created_at = Time.new(2023, 1, 1).utc
      blob = described_class.new(
        id: valid_id,
        data: valid_data,
        size: 100,
        created_at: created_at,
        storage_type: storage_type
      )

      expect(blob.to_h).to eq({
        id: valid_id,
        data: valid_data,
        size: "100",
        created_at: created_at.iso8601
      })
    end
  end
end
