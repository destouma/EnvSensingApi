require 'swagger_helper'

RSpec.describe 'Sensors', type: :request do
  let!(:sensor_type) { SensorType.create!(name: 'Temperature', unit: 'C', pow10multi: -2) }
  let!(:device) { Device.create!(uuid: '123-123-000-000', name: 'MKR1010 BME280') }
  let!(:sensor) { Sensor.create!(uuid: '123-123-000-001', name: 'Temperature Sensor', device: device, sensor_type: sensor_type) }

  path '/api/v1/devices/{device_uuid}/sensors' do
    parameter name: :device_uuid, in: :path, type: :string
    let(:device_uuid) { device.uuid }

    get 'List the sensors of a device' do
      tags 'Sensors'
      produces 'application/json'

      response '200', 'sensors' do
        let(:Authorization) { bearer(read_token) }
        schema type: :object,
               properties: { sensors: { type: :array, items: { '$ref' => '#/components/schemas/sensor' } } },
               required: %w[sensors], additionalProperties: false
        run_test!
      end

      response '404', 'unknown device' do
        let(:Authorization) { bearer(read_token) }
        let(:device_uuid) { 'unknown' }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end
    end

    post 'Add a sensor to a device' do
      tags 'Sensors'
      description 'API key with scope admin.'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          uuid: { type: :string, example: '123-123-000-002' },
          name: { type: :string, example: 'Pressure Sensor' },
          description: { type: :string },
          sensor_type_id: { type: :integer, description: 'See GET /api/v1/sensor_types' }
        },
        required: %w[uuid name sensor_type_id]
      }

      response '201', 'sensor created' do
        let(:Authorization) { bearer(admin_token) }
        let(:body) { { uuid: '123-123-000-002', name: 'Pressure Sensor', sensor_type_id: sensor_type.id } }
        schema '$ref' => '#/components/schemas/sensor'
        run_test!
      end

      response '422', 'invalid sensor (e.g. unknown sensor type)' do
        let(:Authorization) { bearer(admin_token) }
        let(:body) { { uuid: '123-123-000-002', name: 'Pressure Sensor', sensor_type_id: 0 } }
        schema '$ref' => '#/components/schemas/error'
        run_test! do
          expect(response.parsed_body.dig('error', 'details')).to have_key('sensor_type')
        end
      end
    end
  end

  path '/api/v1/sensors/{uuid}' do
    parameter name: :uuid, in: :path, type: :string

    get 'Show a sensor' do
      tags 'Sensors'
      produces 'application/json'

      response '200', 'sensor' do
        let(:Authorization) { bearer(read_token) }
        let(:uuid) { sensor.uuid }
        schema '$ref' => '#/components/schemas/sensor'
        run_test!
      end
    end
  end

  path '/api/v1/sensor_types' do
    get 'List sensor types' do
      tags 'Sensor types'
      produces 'application/json'

      response '200', 'sensor types' do
        let(:Authorization) { bearer(read_token) }
        schema type: :object,
               properties: { sensor_types: { type: :array, items: { '$ref' => '#/components/schemas/sensor_type' } } },
               required: %w[sensor_types], additionalProperties: false
        run_test!
      end
    end
  end
end
