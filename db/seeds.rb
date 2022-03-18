# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
SensorReading.delete_all
Sensor.delete_all
Device.delete_all
SensorType.delete_all

type_temp = SensorType.create(:name => 'Temperature', :unit => 'C', :pow10multi => -2)
type_pres = SensorType.create(:name => 'Pressure', :unit => 'Pa', :pow10multi => -2)
type_batt = SensorType.create(:name => 'Battery Level', :unit => '%', :pow10multi => 0)
type_humidity = SensorType.create(:name => 'Humidity Level', :unit => '%', :pow10multi => -2)
type_camera= SensorType.create(:name => 'Camera', :unit => 'jpg', :pow10multi => 0)


device_sensor = Device.create(:uuid => "123-123-000-000", :name => "MKR1010 BME280", :description => "Test Device ")
sensor_temp = Sensor.create(:uuid => "123-123-000-001", :name => "Temperature Sensor", :description => "Temperature Sensor", :device => device_sensor, :sensor_type => type_temp)
sensor_pres = Sensor.create(:uuid => "123-123-000-002", :name => "Pressure Sensor", :description => "Pressure Sensor", :device => device_sensor, :sensor_type => type_pres)
sensor_humidity = Sensor.create(:uuid => "123-123-000-003", :name => "Humidity Level Sensor", :description => "Humidity Level Sensor", :device => device_sensor, :sensor_type => type_humidity)
sensor_batt = Sensor.create(:uuid => "123-123-000-004", :name => "Battery Level Sensor", :description => "Battery Level Sensor", :device => device_sensor, :sensor_type => type_batt)

device_camera = Device.create(:uuid => "123-123-000-001", :name => "ESP32 CAM", :description => "Test Device ")
sensor_camera = Sensor.create(:uuid => "123-123-000-005", :name => "Camera", :description => "Camera", :device => device_camera, :sensor_type => type_camera)

