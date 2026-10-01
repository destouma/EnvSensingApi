require 'rails_helper'

RSpec.describe 'Model validations' do
  let(:sensor_type) { SensorType.create!(name: 'Temperature', unit: 'C', pow10multi: -2) }
  let(:device) { Device.create!(uuid: 'dev-1', name: 'MKR1010') }

  describe Device do
    it 'requires a unique uuid made of URL-safe characters, and a name' do
      expect(Device.new(uuid: 'dev-2', name: 'x')).to be_valid
      expect(Device.new(uuid: device.uuid, name: 'x')).not_to be_valid
      [ '', 'with space', 'with/slash', 'with.dot', '-leading', 'x' * 65 ].each do |uuid|
        expect(Device.new(uuid: uuid, name: 'x')).not_to be_valid, "expected #{uuid.inspect} to be invalid"
      end
      expect(Device.new(uuid: 'dev-3', name: '')).not_to be_valid
    end

    it 'cannot be destroyed while it has sensors' do
      Sensor.create!(uuid: 's-1', name: 'Temp', device: device, sensor_type: sensor_type)

      expect(device.destroy).to be(false)
      expect(device.errors[:base]).to be_present
    end
  end

  describe Sensor do
    it 'requires a device, a sensor type, a unique uuid and a name' do
      expect(Sensor.new(uuid: 's-1', name: 'Temp', device: device, sensor_type: sensor_type)).to be_valid
      sensor = Sensor.new(uuid: 's-1', name: '')
      expect(sensor).not_to be_valid
      expect(sensor.errors.attribute_names).to include(:device, :sensor_type, :name)
    end
  end

  describe SensorType do
    it 'requires a unique name, a unit and an integer exponent in -12..12' do
      sensor_type
      expect(SensorType.new(name: 'Pressure', unit: 'Pa', pow10multi: -2)).to be_valid
      expect(SensorType.new(name: 'Temperature', unit: 'C', pow10multi: -2)).not_to be_valid
      expect(SensorType.new(name: 'X', unit: '', pow10multi: 0)).not_to be_valid
      expect(SensorType.new(name: 'X', unit: 'u', pow10multi: 13)).not_to be_valid
      expect(SensorType.new(name: 'X', unit: 'u', pow10multi: 1.5)).not_to be_valid
    end
  end

  describe SensorReading do
    let(:sensor) { Sensor.create!(uuid: 's-1', name: 'Temp', device: device, sensor_type: sensor_type) }

    it 'stores 64-bit integer values' do
      reading = SensorReading.create!(sensor: sensor, value: 2**40)
      expect(reading.reload.value).to eq(2**40)
      expect(SensorReading.new(sensor: sensor, value: 2**63)).not_to be_valid
    end

    it 'accepts a clock skew of up to 5 minutes' do
      expect(SensorReading.new(sensor: sensor, value: 1, date_time: 4.minutes.from_now)).to be_valid
      expect(SensorReading.new(sensor: sensor, value: 1, date_time: 6.minutes.from_now)).not_to be_valid
    end
  end
end
