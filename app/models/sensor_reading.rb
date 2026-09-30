# == Schema Information
#
# Table name: sensor_readings
#
#  id          :bigint           not null, primary key
#  date_time   :datetime
#  sensorvalue :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  sensor_id   :bigint
#
# Indexes
#
#  index_sensor_readings_on_sensor_id  (sensor_id)
#
# Foreign Keys
#
#  fk_rails_...  (sensor_id => sensors.id)
#
class SensorReading < ApplicationRecord
  include DeviceDateTime

  # sensorvalue is a 4-byte integer column
  VALUE_RANGE = (-2**31)..(2**31 - 1)

  # The API calls it "value"
  alias_attribute :value, :sensorvalue

  belongs_to :sensor

  validates :value, presence: true, numericality: { only_integer: true, in: VALUE_RANGE }
end
