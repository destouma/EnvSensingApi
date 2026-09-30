class DeviceToken < ApplicationRecord
  include TokenAuthenticatable
  token_prefix "esd_"

  belongs_to :device
end
