class CreateBlobTrackers < ActiveRecord::Migration[8.0]
  def change
    create_table :blob_trackers, id: false do |t|
      t.string :id, primary_key: true, limit: 50
      t.string :blob_id, limit: 50
      t.integer :blob_size
      t.string :storage_type
      t.timestamp :created_at
    end
    add_index :blob_trackers, :id, unique: true
    add_index :blob_trackers, :blob_id, unique: true
  end
end
