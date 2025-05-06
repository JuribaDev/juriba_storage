class CreateStoredBlobs < ActiveRecord::Migration[8.0]
  def change
    create_table :stored_blobs, id: false do |t|
      t.string :id, primary_key: true, limit: 50
      t.binary :data
      t.integer :size
      t.timestamp :created_at
    end
  end
end
