json.sensor do
  json.partial! "api/v1/sensors/sensor", sensor: @sensor
end
json.pictures @pictures, partial: "api/v1/pictures/picture", as: :picture
json.next_cursor @next_cursor
