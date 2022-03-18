# == Schema Information
#
# Table name: pictures
#
#  id         :bigint           not null, primary key
#  date_time  :datetime
#  file_name  :string
#  file_url   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  sensor_id  :bigint           not null
#
# Indexes
#
#  index_pictures_on_sensor_id  (sensor_id)
#
# Foreign Keys
#
#  fk_rails_...  (sensor_id => sensors.id)
#
class Picture < ApplicationRecord
    belongs_to :sensor
end
