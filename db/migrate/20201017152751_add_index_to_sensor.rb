class AddIndexToSensor < ActiveRecord::Migration[5.2]
  def change
    add_index :sensors, :uuid, unique: true
  end
end
