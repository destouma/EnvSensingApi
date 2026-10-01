json.partial! "api/v1/readings/reading", reading: @reading
json.sensor_uuid @reading.sensor.uuid
