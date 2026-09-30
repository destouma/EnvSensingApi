class AddTimeSeriesIndexes < ActiveRecord::Migration[8.1]
  # Readings and pictures are always read per sensor, newest first, keyset paginated on
  # (date_time, id). The composite index serves those queries (scanned backwards) and still
  # covers lookups by sensor_id alone, so the single-column indexes become redundant.
  def change
    add_index :sensor_readings, %i[sensor_id date_time id]
    remove_index :sensor_readings, :sensor_id

    add_index :pictures, %i[sensor_id date_time id]
    remove_index :pictures, :sensor_id
  end
end
