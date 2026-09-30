# == Schema Information
#
# Table name: device_tokens
#
#  id           :bigint           not null, primary key
#  last_used_at :datetime
#  name         :string
#  revoked_at   :datetime
#  token_digest :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  device_id    :bigint           not null
#
# Indexes
#
#  index_device_tokens_on_device_id     (device_id)
#  index_device_tokens_on_token_digest  (token_digest) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (device_id => devices.id)
#
class DeviceToken < ApplicationRecord
  include TokenAuthenticatable
  token_prefix "esd_"

  belongs_to :device
end
