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
class Picture < ApplicationRecord
  include DeviceDateTime

  STORAGE_DIR = Rails.root.join("storage", "pictures")

  belongs_to :sensor

  # The stored (server generated) file name is kept in the file_name column.
  mount_uploader :image, PictureUploader, mount_on: :file_name

  validates :image, presence: true

  def self.storage_dir_for(device)
    STORAGE_DIR.join(device.id.to_s)
  end

  # Absolute path of the stored file, or nil if the file is missing or resolves
  # outside its device's directory (e.g. rows created before file names were server generated).
  def file_path
    return if file_name.blank?

    root = File.realpath(self.class.storage_dir_for(sensor.device))
    path = File.realpath(image.path)
    path if path.start_with?(root + File::SEPARATOR) && File.file?(path)
  rescue Errno::ENOENT
    nil
  end
end
