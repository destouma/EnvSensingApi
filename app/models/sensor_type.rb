# == Schema Information
#
# Table name: sensor_types
#
#  id         :bigint           not null, primary key
#  name       :string
#  pow10multi :integer
#  unit       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class SensorType < ApplicationRecord
  has_many :sensors, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :unit, presence: true, length: { maximum: 32 }
  # Readings are stored as integers: real value = value * 10^pow10multi
  validates :pow10multi, numericality: { only_integer: true, in: -12..12 }
end
