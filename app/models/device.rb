# == Schema Information
#
# Table name: devices
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string
#  uuid        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_devices_on_uuid  (uuid) UNIQUE
#
class Device < ApplicationRecord
  include PublicUuid

  has_many :sensors, dependent: :restrict_with_error
  has_many :device_tokens, dependent: :destroy

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 2000 }
end
