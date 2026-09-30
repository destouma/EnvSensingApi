require 'rails_helper'
require 'tmpdir'

RSpec.describe 'Pictures API', type: :request do
  let(:jpeg_bytes) { "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00fake-jpeg-body".b }

  let(:storage_dir) { Pathname.new(Dir.mktmpdir('pictures')) }
  let(:sensor_type) { SensorType.create!(name: 'Camera', unit: 'jpg', pow10multi: 0) }
  let(:device) { Device.create!(uuid: 'dev-1', name: 'ESP32 CAM') }
  let!(:sensor) { Sensor.create!(uuid: 'sensor-1', name: 'Camera', device: device, sensor_type: sensor_type) }

  before { stub_const('Picture::STORAGE_DIR', storage_dir) }
  after { FileUtils.remove_entry(storage_dir) }

  def uploaded(name, content)
    file = Tempfile.new(['upload', File.extname(name)])
    file.binmode
    file.write(content)
    file.rewind
    Rack::Test::UploadedFile.new(file, 'image/jpeg', true, original_filename: name)
  end

  describe 'POST /api/v1/pictures' do
    it 'rejects a file name that escapes the storage directory' do
      post '/api/v1/pictures.json', params: { sensor_uuid: sensor.uuid, file_name: '../../../../etc/passwd' }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(Picture.count).to eq(0)
    end

    it 'rejects a non-image extension' do
      post '/api/v1/pictures.json', params: { sensor_uuid: sensor.uuid, file_name: 'shell.php' }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'stores a valid picture with the given picture_date_time' do
      post '/api/v1/pictures.json',
           params: { sensor_uuid: sensor.uuid, file_name: 'flower.jpg', picture_date_time: '2022-03-18T12:00:00Z' }

      expect(response).to have_http_status(:no_content)
      picture = Picture.last
      expect(picture.file_name).to eq('flower.jpg')
      expect(picture.file_url).to be_nil
      expect(picture.date_time).to eq(Time.utc(2022, 3, 18, 12))
    end

    it 'still accepts the legacy sensor_date_time parameter' do
      post '/api/v1/pictures.json',
           params: { sensor_uuid: sensor.uuid, file_name: 'flower.jpg', sensor_date_time: '2022-03-18T12:00:00Z' }

      expect(Picture.last.date_time).to eq(Time.utc(2022, 3, 18, 12))
    end
  end

  describe 'GET /api/v1/pictures/file' do
    it 'serves a stored picture' do
      File.binwrite(storage_dir.join('flower.jpg'), jpeg_bytes)
      picture = Picture.create!(sensor: sensor, file_name: 'flower.jpg')

      get '/api/v1/pictures/file.json', params: { id: picture.id }

      expect(response).to have_http_status(:ok)
      expect(response.body.b).to eq(jpeg_bytes)
    end

    it 'does not serve a legacy row whose file name escapes the storage directory' do
      picture = Picture.create!(sensor: sensor, file_name: 'flower.jpg')
      picture.update_columns(file_name: '../../../../etc/passwd', file_url: '/etc/passwd')

      get '/api/v1/pictures/file.json', params: { id: picture.id }

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('root:')
    end

    it 'does not follow a symlink that points outside the storage directory' do
      File.symlink('/etc/passwd', storage_dir.join('link.jpg'))
      picture = Picture.create!(sensor: sensor, file_name: 'link.jpg')

      get '/api/v1/pictures/file.json', params: { id: picture.id }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/pictures/upload' do
    it 'stores a JPEG image' do
      post '/api/v1/pictures/upload.json', params: { file: uploaded('flower.jpg', jpeg_bytes) }

      expect(response).to have_http_status(:no_content)
      expect(File.binread(storage_dir.join('flower.jpg'))).to eq(jpeg_bytes)
    end

    it 'rejects a disallowed extension even with image content' do
      post '/api/v1/pictures/upload.json', params: { file: uploaded('page.html', jpeg_bytes) }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(storage_dir.children).to be_empty
    end

    it 'rejects content that is not an image' do
      post '/api/v1/pictures/upload.json', params: { file: uploaded('fake.jpg', '<script>alert(1)</script>') }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(storage_dir.children).to be_empty
    end

    it 'rejects files larger than 5 MB' do
      post '/api/v1/pictures/upload.json', params: { file: uploaded('big.jpg', jpeg_bytes + ('0' * 5.megabytes)) }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'GET /api/v1/pictures' do
    it 'returns the sensor and a download path instead of the server file path' do
      picture = Picture.create!(sensor: sensor, file_name: 'flower.jpg')

      get '/api/v1/pictures.json', params: { sensor_uuid: sensor.uuid }

      entry = JSON.parse(response.body)['pictures'].first
      expect(entry['sensor']['uuid']).to eq(sensor.uuid)
      expect(entry['picture_file_url']).to eq("/api/v1/pictures/file?id=#{picture.id}")
    end
  end
end
