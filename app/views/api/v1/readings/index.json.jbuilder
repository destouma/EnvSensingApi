json.sensor do
  json.partial! "api/v1/sensors/sensor", sensor: @sensor
end
json.readings @readings, partial: "api/v1/readings/reading", as: :reading
json.next_cursor @next_cursor
