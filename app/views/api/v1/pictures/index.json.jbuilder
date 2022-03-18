json.pictures @pictures do |picture|
  picture.sensor do
    json.id picture.sensor.id
    json.uuid picture.sensor.uuid
    json.name picture.sensor.name
    json.sensor_type do
      json.id picture.sensor.sensor_type.id
      json.name picture.sensor.sensor_type.name
    end
  end
  json.picture_id picture.id
  json.picture_file_name picture.file_name
  json.picture_file_url picture.file_url
  json.picture_date_time picture.date_time
end