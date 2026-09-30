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
    [:get,  '/api/v1/devices.json', :read],
    [:post, '/api/v1/devices.json', :admin],
    [:get,  '/api/v1/sensors.json?device_uuid=dev-1', :read],
    [:post, '/api/v1/sensors.json', :admin],
    [:get,  '/api/v1/sensor_types.json', :read],
    [:get,  '/api/v1/sensor_readings.json?sensor_uuid=sensor-1', :read],
    [:post, '/api/v1/sensor_readings.json', :device],
    [:get,  '/api/v1/pictures.json?sensor_uuid=sensor-1', :read],
    [:get,  '/api/v1/pictures/file.json?id=1', :read],
    [:post, '/api/v1/pictures.json', :device],
    [:post, '/api/v1/pictures/upload.json', :device]
  ]

  endpoints.each do |verb, path, allowed|
    describe "#{verb.upcase} #{path}" do
      it 'rejects a request without a token' do
        call(verb, path)
        expect(response).to have_http_status(:unauthorized)
        expect(response.headers['WWW-Authenticate']).to start_with('Bearer')
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
          if permitted
            begin
              call(verb, path, bearer(instance_exec(&token)))
              expect(response).not_to have_http_status(:unauthorized)
              expect(response).not_to have_http_status(:forbidden)
            rescue ActiveRecord::RecordNotFound, ActionController::ParameterMissing
              # The action ran and failed on the empty test request: authentication passed.
            end
          else
            call(verb, path, bearer(instance_exec(&token)))
            expect(response).to have_http_status(:forbidden)
          end
        end
      end
    end
  end

  it 'keeps GET /api/v1/date_time/current_date_time public' do
    get '/api/v1/date_time/current_date_time.json'
    expect(response).to have_http_status(:ok)
  end

  it 'rejects a token sent with another scheme' do
    get '/api/v1/sensor_types.json', headers: { 'Authorization' => "Basic #{read_key.token}" }
    expect(response).to have_http_status(:unauthorized)
  end

  describe 'device provisioning' do
    it 'returns a device token once when an admin creates a device, and the token works' do
      post '/api/v1/devices.json', params: { uuid: 'dev-new', name: 'New' }, headers: bearer(admin_key.token)

      expect(response).to have_http_status(:ok)
      token = JSON.parse(response.body)['api_token']
      expect(token).to start_with('esd_')
      new_device = Device.find_by!(uuid: 'dev-new')
      expect(new_device.device_tokens.first.token_digest).to eq(Digest::SHA256.hexdigest(token))

      Sensor.create!(uuid: 'sensor-new', name: 'Temp', device: new_device, sensor_type: sensor_type)
      post '/api/v1/sensor_readings.json', params: { sensor_uuid: 'sensor-new', sensor_value: 2150 }, headers: bearer(token)
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /api/v1/sensor_readings' do
    it "records a reading for the device's own sensor and tracks token usage" do
      post '/api/v1/sensor_readings.json', params: { sensor_uuid: sensor.uuid, sensor_value: 2150 },
                                           headers: bearer(device_token.token)

      expect(response).to have_http_status(:ok)
      expect(sensor.sensor_readings.first.sensorvalue).to eq(2150)
      expect(device_token.reload.last_used_at).to be_present
    end

    it "rejects a reading for another device's sensor" do
      other_device = Device.create!(uuid: 'dev-2', name: 'Other')
      other_sensor = Sensor.create!(uuid: 'sensor-2', name: 'Temp', device: other_device, sensor_type: sensor_type)

      post '/api/v1/sensor_readings.json', params: { sensor_uuid: other_sensor.uuid, sensor_value: 1 },
                                           headers: bearer(device_token.token)

      expect(response).to have_http_status(:bad_request)
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
      300.times { get '/api/v1/sensor_types.json', headers: headers }
      expect(response).to have_http_status(:ok)

      get '/api/v1/sensor_types.json', headers: headers
      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers['Retry-After'].to_i).to be_positive
    end
  end
end
