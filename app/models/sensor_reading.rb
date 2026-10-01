# == Schema Information
#
# Table name: sensor_readings
#
#  id         :bigint           not null, primary key
#  date_time  :datetime         not null
#  value      :bigint           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  sensor_id  :bigint           not null
#
# Indexes
#
#  index_sensor_readings_on_sensor_id_and_date_time_and_id  (sensor_id,date_time,id)
#
# Foreign Keys
#
#  fk_rails_...  (sensor_id => sensors.id)
#
class SensorReading < ApplicationRecord
  include DeviceDateTime

  # value is an 8-byte integer column: real value = value * 10^sensor_type.pow10multi
  VALUE_RANGE = (-2**63)..(2**63 - 1)

  belongs_to :sensor

  validates :value, presence: true, numericality: { only_integer: true, in: VALUE_RANGE }
end
