json.extract! sensor, :uuid, :name, :description
json.device_uuid sensor.device.uuid
json.sensor_type do
  json.partial! "api/v1/sensor_types/sensor_type", sensor_type: sensor.sensor_type
end
