json.devices @devices do |device|
  json.id device.id
  json.uuid device.uuid
  json.name device.name
  json.description device.description
  json.sensors device.sensors do |sensor|
    json.id sensor.id
    json.uuid sensor.uuid
    json.name sensor.name
    json.description sensor.description
    json.sensor_type do
      json.id sensor.sensor_type.id
      json.name sensor.sensor_type.name
      json.unit sensor.sensor_type.unit
      json.pow10multi sensor.sensor_type.pow10multi
    end
  end
end