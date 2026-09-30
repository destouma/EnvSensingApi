# == Schema Information
#
# Table name: devices
#
#  id          :bigint           not null, primary key
#  description :text
#  name        :string           not null
#  uuid        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_devices_on_uuid  (uuid) UNIQUE
#
require 'rails_helper'

RSpec.describe Device, type: :model do
  it 'creates a device class' do
    device = Device.new
    expect(device).to be_kind_of(Device)
  end
end
