# spec/integration/sensors_spec.rb
require 'swagger_helper'

describe 'Sensor readings API' do
  let(:Authorization) { "Bearer #{ApiKey.create!(name: 'docs', scope: 'read').token}" }
  path '/api/v1/sensor_readings' do
    get 'Retrives all sensor_readings' do
      tags 'Sensor readings'
      produces 'application/json', 'application/xml'

      response '200', 'sensor readings  found' do
        run_test!
      end
    end

    post 'Creates a sensor reading' do
      tags 'Sensor readings'
      security [deviceToken: []]
      let(:Authorization) do
        device = Device.create!(uuid: 'docs-device', name: 'Docs')
        "Bearer #{device.device_tokens.create!.token}"
      end
      consumes 'application/json', 'application/xml'
      parameter schema: {
          type: :object,
          properties: {
              sensor_uuid: { type: :string },
              sensor_value: { type: :string }
          },
          required: [ 'sensor_uuid', 'sensor_value' ]
      }

      response '201', 'sensor reading created' do
      #   let(:pet) { { name: 'Dodo', status: 'available' } }
        run_test!
      end
      #
      response '422', 'Internal Server Error' do
      #   let(:pet) { { name: 'foo' } }
        run_test!
      end
      response '500', 'invalid request' do

      end
    end
  end


end