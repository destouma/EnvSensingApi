require 'swagger_helper'

RSpec.describe 'Readings', type: :request do
  let!(:sensor_type) { SensorType.create!(name: 'Temperature', unit: 'C', pow10multi: -2) }
  let!(:device) { Device.create!(uuid: '123-123-000-000', name: 'MKR1010 BME280') }
  let!(:sensor) { Sensor.create!(uuid: '123-123-000-001', name: 'Temperature Sensor', device: device, sensor_type: sensor_type) }
  let!(:humidity) { Sensor.create!(uuid: '123-123-000-003', name: 'Humidity Sensor', device: device, sensor_type: sensor_type) }
  let(:device_token) { device.device_tokens.create!.token }

  reading_input = {
    type: :object,
    properties: {
      value: { type: :integer, example: 2150, description: 'Raw integer value, see sensor_type.pow10multi' },
      date_time: { type: :string, format: 'date-time', description: 'Measurement time, defaults to the server time' }
    },
    required: %w[value]
  }

  path '/api/v1/sensors/{sensor_uuid}/readings' do
    parameter name: :sensor_uuid, in: :path, type: :string
    let(:sensor_uuid) { sensor.uuid }

    get 'List the readings of a sensor, newest first' do
      tags 'Readings'
      description 'API key with scope read or admin. Paginated: pass next_cursor as cursor for the next page.'
      produces 'application/json'
      parameter name: :from, in: :query, required: false, schema: { type: :string, format: 'date-time' },
                description: 'Only readings with date_time >= from'
      parameter name: :to, in: :query, required: false, schema: { type: :string, format: 'date-time' },
                description: 'Only readings with date_time < to'
      parameter name: :limit, in: :query, required: false, schema: { type: :integer, minimum: 1, maximum: 1000, default: 100 }
      parameter name: :cursor, in: :query, required: false, schema: { type: :string }

      before do
        3.times { |i| sensor.sensor_readings.create!(value: 2100 + i, date_time: Time.utc(2026, 9, 30, 12, i)) }
      end

      response '200', 'a page of readings' do
        let(:Authorization) { bearer(read_token) }
        let(:limit) { 2 }
        schema type: :object,
               properties: {
                 sensor: { '$ref' => '#/components/schemas/sensor' },
                 readings: { type: :array, items: { '$ref' => '#/components/schemas/reading' } },
                 next_cursor: { '$ref' => '#/components/schemas/next_cursor' }
               },
               required: %w[sensor readings next_cursor], additionalProperties: false
        run_test! do
          expect(response.parsed_body['readings'].pluck('value')).to eq([2102, 2101])
          expect(response.parsed_body['next_cursor']).to be_present
        end
      end

      response '400', 'invalid query parameter' do
        let(:Authorization) { bearer(read_token) }
        let(:cursor) { 'not-a-cursor' }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end

      response '404', 'unknown sensor' do
        let(:Authorization) { bearer(read_token) }
        let(:sensor_uuid) { 'unknown' }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end
    end

    post 'Add a reading' do
      tags 'Readings'
      description 'Device token, for a sensor of that device only. Prefer POST /api/v1/readings to send several readings at once.'
      security [deviceToken: []]
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: reading_input

      response '201', 'reading created' do
        let(:Authorization) { bearer(device_token) }
        let(:body) { { value: 2150, date_time: '2026-09-30T12:00:00Z' } }
        schema '$ref' => '#/components/schemas/reading'
        run_test!
      end

      response '404', "unknown sensor, or a sensor of another device" do
        let(:Authorization) { bearer(device_token) }
        let(:sensor_uuid) { 'unknown' }
        let(:body) { { value: 2150 } }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end

      response '422', 'invalid reading' do
        let(:Authorization) { bearer(device_token) }
        let(:body) { { value: 21.5, date_time: '1970-01-01T00:00:00Z' } }
        schema '$ref' => '#/components/schemas/error'
        run_test! do
          expect(response.parsed_body.dig('error', 'details').keys).to contain_exactly('value', 'date_time')
        end
      end
    end
  end

  path '/api/v1/readings' do
    post 'Add readings for several sensors at once' do
      tags 'Readings'
      description 'Device token. One request per measurement cycle (up to 100 readings), for sensors of that device. ' \
                  'All or nothing: if one reading is invalid, none is stored.'
      security [deviceToken: []]
      consumes 'application/json'
      produces 'application/json'
      parameter name: :body, in: :body, schema: {
        type: :object,
        properties: {
          readings: {
            type: :array, minItems: 1, maxItems: 100,
            items: {
              type: :object,
              properties: { sensor_uuid: { type: :string } }.merge(reading_input[:properties]),
              required: %w[sensor_uuid value]
            }
          }
        },
        required: %w[readings]
      }

      response '201', 'readings created' do
        let(:Authorization) { bearer(device_token) }
        let(:body) do
          { readings: [{ sensor_uuid: sensor.uuid, value: 2150, date_time: '2026-09-30T12:00:00Z' },
                       { sensor_uuid: humidity.uuid, value: 4520, date_time: '2026-09-30T12:00:00Z' }] }
        end
        schema type: :object,
               properties: { readings: { type: :array, items: { '$ref' => '#/components/schemas/reading' } } },
               required: %w[readings], additionalProperties: false
        run_test! do
          expect(SensorReading.count).to eq(2)
        end
      end

      response '422', 'at least one invalid reading, nothing stored' do
        let(:Authorization) { bearer(device_token) }
        let(:body) { { readings: [{ sensor_uuid: sensor.uuid, value: 2150 }, { sensor_uuid: humidity.uuid, value: 'high' }] } }
        schema '$ref' => '#/components/schemas/error'
        run_test! do
          expect(response.parsed_body.dig('error', 'details')).to have_key('readings[1].value')
          expect(SensorReading.count).to eq(0)
        end
      end

      response '400', 'missing or empty readings list' do
        let(:Authorization) { bearer(device_token) }
        let(:body) { { readings: [] } }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end
    end
  end
end
