require 'rails_helper'

RSpec.describe 'API authentication', type: :request do
  let(:sensor_type) { SensorType.create!(name: 'Temperature', unit: 'C', pow10multi: -2) }
  let(:device) { Device.create!(uuid: 'dev-1', name: 'MKR1010') }
  let!(:sensor) { Sensor.create!(uuid: 'sensor-1', name: 'Temp', device: device, sensor_type: sensor_type) }

  let(:device_token) { device.device_tokens.create!(name: 'test') }
  let(:read_key) { ApiKey.create!(name: 'reader', scope: 'read') }
  let(:admin_key) { ApiKey.create!(name: 'admin', scope: 'admin') }

  def bearer(token)
    { 'Authorization' => "Bearer #{token}" }
  end

  def call(verb, path, headers = {})
    send(verb, path, headers: headers)
  end

  # endpoint => which caller is allowed (:read also allows admin keys)
  endpoints = [
    [:get,  '/api/v1/devices', :read],
    [:get,  '/api/v1/devices/dev-1', :read],
    [:post, '/api/v1/devices', :admin],
    [:get,  '/api/v1/devices/dev-1/sensors', :read],
    [:post, '/api/v1/devices/dev-1/sensors', :admin],
    [:get,  '/api/v1/sensors/sensor-1', :read],
    [:get,  '/api/v1/sensor_types', :read],
    [:get,  '/api/v1/sensors/sensor-1/readings', :read],
    [:post, '/api/v1/sensors/sensor-1/readings', :device],
    [:post, '/api/v1/readings', :device],
    [:get,  '/api/v1/sensors/sensor-1/pictures', :read],
    [:post, '/api/v1/sensors/sensor-1/pictures', :device],
    [:get,  '/api/v1/pictures/1/file', :read]
  ]

  endpoints.each do |verb, path, allowed|
    describe "#{verb.upcase} #{path}" do
      it 'rejects a request without a token' do
        call(verb, path)
        expect(response).to have_http_status(:unauthorized)
        expect(response.headers['WWW-Authenticate']).to start_with('Bearer')
        expect(response.parsed_body.dig('error', 'code')).to eq('unauthorized')
      end

      it 'rejects an unknown token' do
        call(verb, path, bearer('esd_not-a-real-token'))
        expect(response).to have_http_status(:unauthorized)
      end

      it 'rejects a revoked token' do
        token = allowed == :device ? device_token : admin_key
        token.revoke!
        call(verb, path, bearer(token.token))
        expect(response).to have_http_status(:unauthorized)
      end

      {
        device: -> { device_token.token },
        read: -> { read_key.token },
        admin: -> { admin_key.token }
      }.each do |caller, token|
        permitted = caller == allowed || (allowed == :read && caller == :admin)

        it "#{permitted ? 'allows' : 'forbids'} a #{caller} token" do
          call(verb, path, bearer(instance_exec(&token)))
          if permitted
            # The empty test request may fail validation (400/404/422), but it got past authentication.
            expect(response).not_to have_http_status(:unauthorized)
            expect(response).not_to have_http_status(:forbidden)
          else
            expect(response).to have_http_status(:forbidden)
            expect(response.parsed_body.dig('error', 'code')).to eq('forbidden')
          end
        end
      end
    end
  end

  it 'keeps GET /api/v1/time public' do
    get '/api/v1/time'
    expect(response).to have_http_status(:ok)
  end

  it 'rejects a token sent with another scheme' do
    get '/api/v1/sensor_types', headers: { 'Authorization' => "Basic #{read_key.token}" }
    expect(response).to have_http_status(:unauthorized)
  end

  describe 'device provisioning' do
    it 'returns a device token once when an admin creates a device, and the token works' do
      post '/api/v1/devices', params: { uuid: 'dev-new', name: 'New' }, headers: bearer(admin_key.token), as: :json

      expect(response).to have_http_status(:created)
      token = response.parsed_body['api_token']
      expect(token).to start_with('esd_')
      new_device = Device.find_by!(uuid: 'dev-new')
      expect(new_device.device_tokens.first.token_digest).to eq(Digest::SHA256.hexdigest(token))

      get '/api/v1/devices/dev-new', headers: bearer(read_key.token)
      expect(response.parsed_body).not_to have_key('api_token')

      Sensor.create!(uuid: 'sensor-new', name: 'Temp', device: new_device, sensor_type: sensor_type)
      post '/api/v1/sensors/sensor-new/readings', params: { value: 2150 }, headers: bearer(token), as: :json
      expect(response).to have_http_status(:created)
    end
  end

  describe 'device isolation' do
    let(:other_device) { Device.create!(uuid: 'dev-2', name: 'Other') }
    let!(:other_sensor) { Sensor.create!(uuid: 'sensor-2', name: 'Temp', device: other_device, sensor_type: sensor_type) }

    it "records a reading for the device's own sensor and tracks token usage" do
      post '/api/v1/sensors/sensor-1/readings', params: { value: 2150 }, headers: bearer(device_token.token), as: :json

      expect(response).to have_http_status(:created)
      expect(sensor.sensor_readings.first.value).to eq(2150)
      expect(device_token.reload.last_used_at).to be_present
    end

    it "rejects a reading for another device's sensor as not found" do
      post '/api/v1/sensors/sensor-2/readings', params: { value: 1 }, headers: bearer(device_token.token), as: :json

      expect(response).to have_http_status(:not_found)
      expect(SensorReading.count).to eq(0)
    end

    it "rejects a whole batch that contains another device's sensor" do
      post '/api/v1/readings',
           params: { readings: [{ sensor_uuid: 'sensor-1', value: 1 }, { sensor_uuid: 'sensor-2', value: 2 }] },
           headers: bearer(device_token.token), as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig('error', 'details')).to eq('readings[1].sensor_uuid' => ['sensor not found'])
      expect(SensorReading.count).to eq(0)
    end
  end

  describe 'rate limiting' do
    before do
      Rack::Attack.enabled = true
      Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    end

    after do
      Rack::Attack.reset!
      Rack::Attack.enabled = false
    end

    it 'throttles a token after 300 requests in 5 minutes' do
      headers = bearer(read_key.token)
      300.times { get '/api/v1/sensor_types', headers: headers }
      expect(response).to have_http_status(:ok)

      get '/api/v1/sensor_types', headers: headers
      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers['Retry-After'].to_i).to be_positive
    end
  end
end
