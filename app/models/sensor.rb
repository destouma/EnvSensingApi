# == Schema Information
#
# Table name: sensors
#
#  id             :bigint           not null, primary key
#  description    :text
#  name           :string
#  uuid           :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  device_id      :bigint
#  sensor_type_id :bigint
#
# Indexes
#
#  index_sensors_on_device_id       (device_id)
#  index_sensors_on_sensor_type_id  (sensor_type_id)
#  index_sensors_on_uuid            (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (device_id => devices.id)
#  fk_rails_...  (sensor_type_id => sensor_types.id)
#
class Sensor < ApplicationRecord
  belongs_to :device
  belongs_to :sensor_type
  has_many :sensor_readings
  has_many :pictures
end
