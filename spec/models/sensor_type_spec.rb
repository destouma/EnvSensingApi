# == Schema Information
#
# Table name: sensor_types
#
#  id         :bigint           not null, primary key
#  name       :string           not null
#  pow10multi :integer          not null
#  unit       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_sensor_types_on_name  (name) UNIQUE
#
require 'rails_helper'

RSpec.describe SensorType, type: :model do
end
