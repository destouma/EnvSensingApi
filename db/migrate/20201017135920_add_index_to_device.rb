class AddIndexToDevice < ActiveRecord::Migration[5.2]
  def change
    add_index :devices, :uuid, unique: true
  end
end
