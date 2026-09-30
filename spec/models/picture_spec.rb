# == Schema Information
#
# Table name: pictures
#
#  id         :bigint           not null, primary key
#  date_time  :datetime         not null
#  file_name  :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  sensor_id  :bigint           not null
#
# Indexes
#
#  index_pictures_on_sensor_id_and_date_time_and_id  (sensor_id,date_time,id)
#
# Foreign Keys
#
#  fk_rails_...  (sensor_id => sensors.id)
#
require 'rails_helper'

RSpec.describe Picture, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
