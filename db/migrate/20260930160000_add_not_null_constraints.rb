class AddNotNullConstraints < ActiveRecord::Migration[8.1]
  # Columns the application requires (model validations); the database now enforces them too.
  REQUIRED = {
    devices: %i[uuid name],
    sensors: %i[uuid name device_id sensor_type_id],
    sensor_types: %i[name unit pow10multi],
    sensor_readings: %i[sensor_id sensorvalue date_time],
    pictures: %i[file_name date_time]
  }.freeze

  def up
    # Values that can be derived safely:
    # - date_time defaults to when the row was stored (readings stored before the date_time column
    #   existed, pictures whose picture_date_time was ignored by an old bug);
    # - a missing name falls back to the uuid.
    execute "UPDATE sensor_readings SET date_time = created_at WHERE date_time IS NULL"
    execute "UPDATE pictures SET date_time = created_at WHERE date_time IS NULL"
    execute "UPDATE devices SET name = uuid WHERE (name IS NULL OR name = '') AND uuid IS NOT NULL"
    execute "UPDATE sensors SET name = uuid WHERE (name IS NULL OR name = '') AND uuid IS NOT NULL"

    # Anything else cannot be guessed: stop and let a person decide rather than deleting data.
    problems = REQUIRED.flat_map do |table, columns|
      columns.filter_map do |column|
        count = select_value("SELECT COUNT(*) FROM #{table} WHERE #{column} IS NULL").to_i
        "#{table}.#{column} is NULL in #{count} row(s)" if count.positive?
      end
    end
    duplicates = select_values("SELECT name FROM sensor_types GROUP BY name HAVING COUNT(*) > 1")
    problems << "sensor_types.name is duplicated: #{duplicates.join(', ')}" if duplicates.any?
    if problems.any?
      raise <<~MSG
        Cannot add NOT NULL constraints, fix or delete these rows first (nothing was changed):
          #{problems.join("\n  ")}
      MSG
    end

    REQUIRED.each { |table, columns| columns.each { |column| change_column_null table, column, false } }
    add_index :sensor_types, :name, unique: true
  end

  def down
    remove_index :sensor_types, :name
    REQUIRED.each { |table, columns| columns.each { |column| change_column_null table, column, true } }
  end
end
