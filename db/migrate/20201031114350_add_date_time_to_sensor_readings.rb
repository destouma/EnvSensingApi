class AddDateTimeToSensorReadings < ActiveRecord::Migration[5.2]
  def change
    add_column :sensor_readings, :date_time, :datetime
  end
end
