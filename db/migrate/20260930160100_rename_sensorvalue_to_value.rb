class RenameSensorvalueToValue < ActiveRecord::Migration[8.1]
  # The API already calls it "value". bigint: raw values are scaled by 10^pow10multi,
  # so a 4-byte integer overflows quickly (e.g. pressure in mPa).
  # Note: changing the type rewrites the table (brief write lock on sensor_readings).
  def up
    rename_column :sensor_readings, :sensorvalue, :value
    change_column :sensor_readings, :value, :bigint
  end

  def down
    change_column :sensor_readings, :value, :integer
    rename_column :sensor_readings, :value, :sensorvalue
  end
end
