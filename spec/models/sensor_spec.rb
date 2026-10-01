# == Schema Information
#
# Table name: sensors
#
#  id             :bigint           not null, primary key
#  description    :text
#  name           :string           not null
#  uuid           :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  device_id      :bigint           not null
#  sensor_type_id :bigint           not null
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
require 'rails_helper'

RSpec.describe Sensor, type: :model do
end
