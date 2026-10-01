require 'rails_helper'
require 'tmpdir'

RSpec.describe 'Pictures API', type: :request do
  let(:jpeg_bytes) { "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00fake-jpeg-body".b }
  let(:png_bytes) { "\x89PNG\r\n\x1A\nfake-png-body".b }

  let(:storage_dir) { Pathname.new(Dir.mktmpdir('pictures')) }
  let(:sensor_type) { SensorType.create!(name: 'Camera', unit: 'jpg', pow10multi: 0) }
  let(:device) { Device.create!(uuid: 'dev-1', name: 'ESP32 CAM') }
  let!(:sensor) { Sensor.create!(uuid: 'sensor-1', name: 'Camera', device: device, sensor_type: sensor_type) }
  let(:device_dir) { storage_dir.join(device.id.to_s).tap(&:mkpath) }
  let(:device_headers) { bearer(device.device_tokens.create!.token) }
  let(:read_headers) { bearer(ApiKey.create!(name: 'reader', scope: 'read').token) }

  before { stub_const('Picture::STORAGE_DIR', storage_dir) }
  after { FileUtils.remove_entry(storage_dir) }

  def bearer(token)
    { 'Authorization' => "Bearer #{token}" }
  end

  def uploaded(name, content)
    file = Tempfile.new([ 'upload', File.extname(name) ])
    file.binmode
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file, 'image/jpeg', true, original_filename: name)
  end

  def upload(name, content, headers: device_headers, sensor_uuid: sensor.uuid, **params)
    post "/api/v1/sensors/#{sensor_uuid}/pictures", params: { file: uploaded(name, content), **params }, headers: headers
  end

  def stored_files
    storage_dir.glob('**/*').select(&:file?)
  end

  describe 'POST /api/v1/sensors/:uuid/pictures' do
    it "stores a JPEG under a server generated name in the device's directory" do
      upload('flower.jpg', jpeg_bytes, date_time: '2022-03-18T12:00:00Z')

      expect(response).to have_http_status(:created)
      picture = Picture.last
      expect(picture.file_name).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\.jpg\z/)
      expect(File.binread(device_dir.join(picture.file_name))).to eq(jpeg_bytes)
      expect(picture.date_time).to eq(Time.utc(2022, 3, 18, 12))
      expect(response.parsed_body).to include('id' => picture.id, 'sensor_uuid' => sensor.uuid,
                                              'size' => jpeg_bytes.bytesize, 'url' => "/api/v1/pictures/#{picture.id}/file")
    end

    it 'ignores a client file name that tries to escape the storage directory' do
      upload('../../../../etc/passwd.jpg', jpeg_bytes)

      expect(response).to have_http_status(:created)
      expect(stored_files.map(&:dirname)).to eq([ device_dir ])
    end

    it 'never overwrites an existing picture, even with the same client file name' do
      upload('flower.jpg', jpeg_bytes)
      upload('flower.jpg', png_bytes)

      expect(Picture.count).to eq(2)
      expect(stored_files.map { |f| File.binread(f) }).to contain_exactly(jpeg_bytes, png_bytes)
    end

    it "cannot add a picture to another device's sensor" do
      other_device = Device.create!(uuid: 'dev-2', name: 'Other')
      Sensor.create!(uuid: 'sensor-2', name: 'Camera', device: other_device, sensor_type: sensor_type)

      upload('flower.jpg', jpeg_bytes, sensor_uuid: 'sensor-2')

      expect(response).to have_http_status(:not_found)
      expect(Picture.count).to eq(0)
      expect(stored_files).to be_empty
    end

    it 'rejects a non-image extension even with image content' do
      upload('shell.php', jpeg_bytes)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig('error', 'details', 'image')).to be_present
      expect(stored_files).to be_empty
    end

    it 'rejects content that is not an image' do
      upload('fake.jpg', '<script>alert(1)</script>')

      expect(response).to have_http_status(:unprocessable_content)
      expect(stored_files).to be_empty
    end

    it 'rejects files larger than 5 MB' do
      upload('big.jpg', jpeg_bytes + ('0' * 5.megabytes))

      expect(response).to have_http_status(:unprocessable_content)
      expect(stored_files).to be_empty
    end

    it 'rejects a file parameter that is not an upload (a string would be read as a server path)' do
      post "/api/v1/sensors/#{sensor.uuid}/pictures", params: { file: '/etc/hostname' }, headers: device_headers

      expect(response).to have_http_status(:bad_request)
      expect(stored_files).to be_empty
    end

    it 'rejects a request without a file' do
      post "/api/v1/sensors/#{sensor.uuid}/pictures", params: {}, headers: device_headers

      expect(response).to have_http_status(:bad_request)
    end

    it 'rejects an invalid date_time' do
      upload('flower.jpg', jpeg_bytes, date_time: 'yesterday')

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body.dig('error', 'details', 'date_time')).to be_present
    end

    it 'leaves no cached copy in public/' do
      upload('flower.jpg', jpeg_bytes)

      expect(Rails.root.join('public/uploads')).not_to exist
    end
  end

  describe 'GET /api/v1/pictures/:id/file' do
    it 'serves a stored picture' do
      upload('flower.jpg', jpeg_bytes)

      get "/api/v1/pictures/#{Picture.last.id}/file", headers: read_headers

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('image/jpeg')
      expect(response.body.b).to eq(jpeg_bytes)
    end

    it 'does not serve a legacy row whose file name escapes the storage directory' do
      upload('flower.jpg', jpeg_bytes)
      picture = Picture.last
      picture.update_columns(file_name: '../../../../etc/passwd')

      get "/api/v1/pictures/#{picture.id}/file", headers: read_headers

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('root:')
    end

    it 'does not follow a symlink that points outside the storage directory' do
      upload('flower.jpg', jpeg_bytes)
      picture = Picture.last
      File.symlink('/etc/passwd', device_dir.join('link.jpg'))
      picture.update_columns(file_name: 'link.jpg')

      get "/api/v1/pictures/#{picture.id}/file", headers: read_headers

      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 for an unknown picture' do
      get '/api/v1/pictures/999999/file', headers: read_headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body.dig('error', 'code')).to eq('not_found')
    end
  end

  describe 'GET /api/v1/sensors/:uuid/pictures' do
    it 'returns the sensor and download paths, never server file paths' do
      upload('flower.jpg', jpeg_bytes)

      get "/api/v1/sensors/#{sensor.uuid}/pictures", headers: read_headers

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['sensor']['uuid']).to eq(sensor.uuid)
      expect(body['pictures'].sole['url']).to eq("/api/v1/pictures/#{Picture.last.id}/file")
      expect(response.body).not_to include(storage_dir.to_s)
      expect(body['next_cursor']).to be_nil
    end
  end
end
