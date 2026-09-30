json.extract! picture, :id, :date_time
json.sensor_uuid picture.sensor.uuid
json.size picture.image.size
json.url file_api_v1_picture_path(picture)
