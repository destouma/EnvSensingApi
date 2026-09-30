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
require 'tmpdir'

RSpec.describe Picture, type: :model do
  let(:storage_dir) { Pathname.new(Dir.mktmpdir('pictures')) }
  let(:sensor_type) { SensorType.create!(name: 'Camera', unit: 'jpg', pow10multi: 0) }
  let(:device) { Device.create!(uuid: 'dev-1', name: 'ESP32 CAM') }
  let(:sensor) { Sensor.create!(uuid: 'cam-1', name: 'Camera', device: device, sensor_type: sensor_type) }
  let(:picture) { sensor.pictures.create!(image: jpeg_upload('capture.jpg')) }

  before { stub_const('Picture::STORAGE_DIR', storage_dir) }
  after { FileUtils.remove_entry(storage_dir) }

  it "stores the file in its device's directory under a generated name" do
    expect(picture.file_path).to eq(File.realpath(storage_dir.join(device.id.to_s, picture.file_name)))
    expect(picture.file_name).not_to eq('capture.jpg')
  end

  it 'defaults date_time to the time of the upload' do
    freeze_time { expect(sensor.pictures.create!(image: jpeg_upload).date_time).to eq(Time.current) }
  end

  it 'requires an image' do
    expect(sensor.pictures.new).not_to be_valid
  end

  describe '#file_path' do
    it 'is nil when the file is missing' do
      File.delete(picture.file_path)
      expect(picture.file_path).to be_nil
    end

    it 'is nil for a file name that escapes the device directory' do
      other_device_dir = storage_dir.join('999').tap(&:mkpath)
      File.write(other_device_dir.join('other.jpg'), 'x')
      picture.update_columns(file_name: '../999/other.jpg')

      expect(picture.reload.file_path).to be_nil
    end
  end
end
