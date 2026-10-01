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
class SensorType < ApplicationRecord
  has_many :sensors, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :unit, presence: true, length: { maximum: 32 }
  # Readings are stored as integers: real value = value * 10^pow10multi
  validates :pow10multi, numericality: { only_integer: true, in: -12..12 }
end
