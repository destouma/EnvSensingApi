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
  STORAGE_DIR = Rails.root.join("storage", "pictures")
  # Plain file name only: no directory separators, no leading dot, image extension.
  FILE_NAME_FORMAT = /\A[\w+-][\w.+-]*\.(jpe?g|png)\z/i

  belongs_to :sensor

  validates :file_name, presence: true, format: { with: FILE_NAME_FORMAT }

  # Absolute path of the stored file, or nil if the file is missing or
  # resolves outside STORAGE_DIR (e.g. rows created before file names were validated).
  def file_path
    return unless file_name.to_s.match?(FILE_NAME_FORMAT)

    root = File.realpath(STORAGE_DIR)
    path = File.realpath(STORAGE_DIR.join(file_name))
    path if path.start_with?(root + File::SEPARATOR) && File.file?(path)
  rescue Errno::ENOENT
    nil
  end
end
