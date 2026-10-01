# Demo data for development: the sensor types, the MKR1010 BME280 weather station and the ESP32 camera.
# Idempotent: running it again only adds what is missing and never deletes anything.
#
#   bin/rails db:seed
#
# Sensor types are reference data every installation needs; the demo devices are only created
# outside production (set SEED_DEMO_DEVICES=1 to create them in production anyway).

sensor_types = {
  "Temperature" => { unit: "C", pow10multi: -2 },
  "Pressure" => { unit: "Pa", pow10multi: -2 },
  "Battery Level" => { unit: "%", pow10multi: 0 },
  "Humidity Level" => { unit: "%", pow10multi: -2 },
  "Camera" => { unit: "jpg", pow10multi: 0 }
}.to_h do |name, attributes|
  [ name, SensorType.find_or_create_by!(name: name) { |type| type.assign_attributes(attributes) } ]
end

return if Rails.env.production? && ENV["SEED_DEMO_DEVICES"].blank?

devices = {
  "123-123-000-000" => {
    name: "MKR1010 BME280",
    sensors: {
      "123-123-000-001" => [ "Temperature Sensor", "Temperature" ],
      "123-123-000-002" => [ "Pressure Sensor", "Pressure" ],
      "123-123-000-003" => [ "Humidity Level Sensor", "Humidity Level" ],
      "123-123-000-004" => [ "Battery Level Sensor", "Battery Level" ]
    }
  },
  "123-123-000-001" => {
    name: "ESP32 CAM",
    sensors: { "123-123-000-005" => [ "Camera", "Camera" ] }
  }
}

devices.each do |uuid, spec|
  device = Device.find_or_create_by!(uuid: uuid) { |d| d.assign_attributes(name: spec[:name], description: "Demo device") }
  spec[:sensors].each do |sensor_uuid, (name, type)|
    Sensor.find_or_create_by!(uuid: sensor_uuid) do |sensor|
      sensor.assign_attributes(name: name, description: name, device: device, sensor_type: sensor_types.fetch(type))
    end
  end

  # Development convenience: a token for each demo device, printed once (only the digest is stored).
  next unless Rails.env.development? && device.device_tokens.active.none?

  puts "Device token for #{uuid} (#{device.name}): #{device.device_tokens.create!(name: 'seed').token}"
end

if Rails.env.development? && ApiKey.active.where(name: "seed-admin").none?
  puts "Admin API key: #{ApiKey.create!(name: 'seed-admin', scope: 'admin').token}"
end
