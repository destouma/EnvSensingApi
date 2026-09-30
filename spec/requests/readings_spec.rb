require 'rails_helper'

RSpec.describe 'Readings API', type: :request do
  let(:sensor_type) { SensorType.create!(name: 'Temperature', unit: 'C', pow10multi: -2) }
  let(:device) { Device.create!(uuid: 'dev-1', name: 'MKR1010') }
  let!(:sensor) { Sensor.create!(uuid: 'sensor-1', name: 'Temp', device: device, sensor_type: sensor_type) }
  let(:read_headers) { { 'Authorization' => bearer(read_token) } }
  let(:device_headers) { { 'Authorization' => bearer(device.device_tokens.create!.token) } }

  describe 'GET /api/v1/sensors/:uuid/readings' do
    let(:start) { Time.utc(2026, 9, 30, 12) }

    before do
      # Two readings share a timestamp to exercise the (date_time, id) tie-break.
      [0, 1, 2, 2, 3].each_with_index do |minute, i|
        sensor.sensor_readings.create!(value: i, date_time: start + minute.minutes)
      end
      other = Sensor.create!(uuid: 'sensor-2', name: 'Other', device: device, sensor_type: sensor_type)
      other.sensor_readings.create!(value: 99, date_time: start)
    end

    def fetch(**params)
      get '/api/v1/sensors/sensor-1/readings', params: params, headers: read_headers
      response.parsed_body
    end

    it 'walks through every reading of the sensor exactly once, newest first' do
      values = []
      cursor = nil
      pages = 0
      loop do
        body = fetch(limit: 2, cursor: cursor)
        values.concat(body['readings'].pluck('value'))
        pages += 1
        cursor = body['next_cursor']
        break if cursor.nil?
      end

      expect(values).to eq([4, 3, 2, 1, 0])
      expect(pages).to eq(3)
    end

    it 'filters by from (inclusive) and to (exclusive)' do
      body = fetch(from: (start + 1.minute).iso8601, to: (start + 3.minutes).iso8601)
      expect(body['readings'].pluck('value')).to eq([3, 2, 1])
    end

    it 'returns 400 for an invalid limit, date or cursor' do
      [{ limit: 0 }, { limit: 1001 }, { limit: 'ten' }, { from: 'yesterday' }, { cursor: 'garbage' }].each do |params|
        fetch(**params)
        expect(response).to have_http_status(:bad_request), "expected 400 for #{params}"
        expect(response.parsed_body.dig('error', 'code')).to eq('bad_request')
      end
    end
  end

  describe 'POST /api/v1/sensors/:uuid/readings' do
    def post_reading(body)
      post '/api/v1/sensors/sensor-1/readings', params: body, headers: device_headers, as: :json
    end

    it 'defaults date_time to the server time' do
      freeze_time do
        post_reading(value: 2150)
        expect(response).to have_http_status(:created)
        expect(SensorReading.last.date_time).to eq(Time.current)
      end
    end

    it 'accepts a numeric string value' do
      post_reading(value: '2150')
      expect(response).to have_http_status(:created)
      expect(response.parsed_body['value']).to eq(2150)
    end

    it 'rejects decimals, out of range values and implausible dates' do
      [
        [{ value: 21.5 }, 'value'],
        [{ value: 2**63 }, 'value'],
        [{}, 'value'],
        [{ value: 1, date_time: 'not a date' }, 'date_time'],
        [{ value: 1, date_time: '1970-01-01T00:00:00Z' }, 'date_time'],
        [{ value: 1, date_time: 1.hour.from_now.iso8601 }, 'date_time']
      ].each do |body, field|
        post_reading(body)
        expect(response).to have_http_status(:unprocessable_content), "expected 422 for #{body}"
        expect(response.parsed_body.dig('error', 'details')).to have_key(field)
      end
      expect(SensorReading.count).to eq(0)
    end
  end

  describe 'POST /api/v1/readings' do
    it 'rejects more than 100 readings' do
      readings = Array.new(101) { { sensor_uuid: 'sensor-1', value: 1 } }
      post '/api/v1/readings', params: { readings: readings }, headers: device_headers, as: :json

      expect(response).to have_http_status(:bad_request)
      expect(SensorReading.count).to eq(0)
    end

    it 'rejects a body without readings' do
      post '/api/v1/readings', params: { value: 1 }, headers: device_headers, as: :json

      expect(response).to have_http_status(:bad_request)
    end
  end

  it 'returns 400 with the standard error shape for malformed JSON' do
    post '/api/v1/sensors/sensor-1/readings', params: '{"value": ',
                                              headers: device_headers.merge('Content-Type' => 'application/json')

    expect(response).to have_http_status(:bad_request)
    expect(response.parsed_body.dig('error', 'code')).to eq('bad_request')
  end
end
