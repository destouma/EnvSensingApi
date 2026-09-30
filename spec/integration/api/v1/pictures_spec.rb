require 'swagger_helper'
require 'tmpdir'

RSpec.describe 'Pictures', type: :request do
  let!(:sensor_type) { SensorType.create!(name: 'Camera', unit: 'jpg', pow10multi: 0) }
  let!(:device) { Device.create!(uuid: '123-123-000-001', name: 'ESP32 CAM') }
  let!(:sensor) { Sensor.create!(uuid: '123-123-000-005', name: 'Camera', device: device, sensor_type: sensor_type) }
  let(:storage_dir) { Pathname.new(Dir.mktmpdir('pictures')) }

  before { stub_const('Picture::STORAGE_DIR', storage_dir) }
  after { FileUtils.remove_entry(storage_dir) }

  def create_picture
    sensor.pictures.create!(image: jpeg_upload, date_time: Time.utc(2026, 9, 30, 12))
  end

  path '/api/v1/sensors/{sensor_uuid}/pictures' do
    parameter name: :sensor_uuid, in: :path, type: :string
    let(:sensor_uuid) { sensor.uuid }

    get 'List the pictures of a sensor, newest first' do
      tags 'Pictures'
      description 'API key with scope read or admin. Paginated like the readings.'
      produces 'application/json'
      parameter name: :from, in: :query, required: false, schema: { type: :string, format: 'date-time' }
      parameter name: :to, in: :query, required: false, schema: { type: :string, format: 'date-time' }
      parameter name: :limit, in: :query, required: false, schema: { type: :integer, minimum: 1, maximum: 1000, default: 100 }
      parameter name: :cursor, in: :query, required: false, schema: { type: :string }

      response '200', 'a page of pictures' do
        before { create_picture }
        let(:Authorization) { bearer(read_token) }
        schema type: :object,
               properties: {
                 sensor: { '$ref' => '#/components/schemas/sensor' },
                 pictures: { type: :array, items: { '$ref' => '#/components/schemas/picture' } },
                 next_cursor: { '$ref' => '#/components/schemas/next_cursor' }
               },
               required: %w[sensor pictures next_cursor], additionalProperties: false
        run_test!
      end
    end

    post 'Upload a picture' do
      tags 'Pictures'
      description 'Device token, for a sensor of that device only. JPEG or PNG, up to 5 MB. ' \
                  'The file is stored under a server generated name.'
      security [deviceToken: []]
      consumes 'multipart/form-data'
      produces 'application/json'
      # rswag documents only the first form parameter that has a schema, so it carries the whole
      # multipart body; date_time is declared without a schema only so the request sends it.
      parameter name: :file, in: :formData, required: true, schema: {
        type: :object,
        properties: {
          file: { type: :string, format: :binary, description: 'JPEG or PNG, up to 5 MB' },
          date_time: { type: :string, format: 'date-time', description: 'Capture time, defaults to the server time' }
        },
        required: %w[file]
      }
      parameter name: :date_time, in: :formData, type: :string, required: false

      response '201', 'picture stored' do
        let(:Authorization) { bearer(device.device_tokens.create!.token) }
        let(:file) { jpeg_upload('capture.jpg') }
        let(:date_time) { '2026-09-30T12:00:00Z' }
        schema '$ref' => '#/components/schemas/picture'
        run_test!
      end

      response '422', 'not a JPEG/PNG image, or too large' do
        let(:Authorization) { bearer(device.device_tokens.create!.token) }
        let(:file) { Rack::Test::UploadedFile.new(StringIO.new('not an image'), 'image/jpeg', original_filename: 'capture.jpg') }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end
    end
  end

  path '/api/v1/pictures/{id}/file' do
    parameter name: :id, in: :path, type: :integer

    get 'Download a picture' do
      tags 'Pictures'
      description 'API key with scope read or admin.'
      produces 'image/jpeg', 'image/png', 'application/json'

      response '200', 'the image file' do
        let(:Authorization) { bearer(read_token) }
        let(:id) { create_picture.id }
        run_test! do
          expect(response.media_type).to eq('image/jpeg')
        end
      end

      response '404', 'unknown picture' do
        let(:Authorization) { bearer(read_token) }
        let(:id) { 0 }
        schema '$ref' => '#/components/schemas/error'
        run_test!
      end
    end
  end
end
