class CreateDeviceTokens < ActiveRecord::Migration[6.0]
  def change
    create_table :device_tokens do |t|
      t.references :device, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.string :name
      t.datetime :last_used_at
      t.datetime :revoked_at
      t.timestamps
    end
    add_index :device_tokens, :token_digest, unique: true
  end
end
