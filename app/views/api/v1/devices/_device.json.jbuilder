json.extract! device, :uuid, :name, :description, :created_at
json.sensors device.sensors, partial: "api/v1/sensors/sensor", as: :sensor
