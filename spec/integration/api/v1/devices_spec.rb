require 'swagger_helper'

RSpec.describe 'Devices', type: :request do
  let(:sensor_type) { SensorType.create!(name: 'Temperature', unit: 'C', pow10multi: -2) }
  let!(:device) { Device.create!(uuid: '123-123-000-000', name: 'MKR1010 BME280', description: 'Living room') }

  before { Sensor.create!(uuid: '123-123-000-001', name: 'Temperature Sensor', device: device, sensor_type: sensor_type) }

  path '/api/v1/devices' do
    get 'List devices with their sensors' do
      tags 'Devices'
      description 'API key with scope read or admin.'
      produces 'application/json'

      response '200', 'devices' do
        let(:Authorization) { bearer(read_token) }
        schema type: :object,
               properties: { devices: { type: :array, items: { '$ref' => '#/components/schemas/device' } } },
               required: %w[devices], additionalProperties: false
        run_test!
      end

      response '401', 'missing or invalid token' do
        let(:Authorization) { bearer('esk_invalid') }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end

      response '403', 'token not allowed (e.g. a device token)' do
        let(:Authorization) { bearer(device.device_tokens.create!.token) }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end
    end

    post 'Create a device' do
      tags 'Devices'
      description 'API key with scope admin. The response contains the device token (api_token), ' \
                  'shown only once: store it in the device firmware.'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          uuid: { type: :string, example: '123-123-000-010' },
          name: { type: :string, example: 'ESP32 CAM' },
          description: { type: :string, example: 'Garden camera' }
        },
        required: %w[uuid name]
      }

      response '201', 'device created' do
        let(:Authorization) { bearer(admin_token) }
        let(:body) { { uuid: '123-123-000-010', name: 'ESP32 CAM', description: 'Garden camera' } }
        schema '$ref' => '#/components/schemas/device_with_token'
        run_test!
      end

      response '422', 'invalid device (e.g. duplicate uuid)' do
        let(:Authorization) { bearer(admin_token) }
        let(:body) { { uuid: device.uuid, name: '' } }
        schema '$ref' => '#/components/schemas/error'
        run_test! do
          expect(response.parsed_body.dig('error', 'details').keys).to contain_exactly('uuid', 'name')
        end
      end

      response '403', 'API key without admin scope' do
        let(:Authorization) { bearer(read_token) }
        let(:body) { { uuid: 'x', name: 'x' } }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end
    end
  end

  path '/api/v1/devices/{uuid}' do
    parameter name: :uuid, in: :path, type: :string

    get 'Show a device with its sensors' do
      tags 'Devices'
      produces 'application/json'

      response '200', 'device' do
        let(:Authorization) { bearer(read_token) }
        let(:uuid) { device.uuid }
        schema '$ref' => '#/components/schemas/device'
        run_test!
      end

      response '404', 'unknown device' do
        let(:Authorization) { bearer(read_token) }
        let(:uuid) { 'unknown' }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end
    end
  end
end
