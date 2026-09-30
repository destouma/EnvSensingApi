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
require 'rails_helper'

RSpec.describe SensorReading, type: :model do
end
