module ApiHelpers
  def bearer(token)
    "Bearer #{token}"
  end

  def read_token
    ApiKey.create!(name: 'reader', scope: 'read').token
  end

  def admin_token
    ApiKey.create!(name: 'admin', scope: 'admin').token
  end
end

module UploadHelpers
  JPEG_BYTES = "\xFF\xD8\xFF\xE0\x00\x10JFIF\x00example-jpeg-body".b.freeze

  def jpeg_upload(name = 'picture.jpg')
    file = Tempfile.new([ 'upload', File.extname(name) ])
    file.binmode
    file.write(JPEG_BYTES)
    file.rewind
    Rack::Test::UploadedFile.new(file, 'image/jpeg', true, original_filename: name)
  end
end

RSpec.configure do |config|
  config.include ApiHelpers
  config.include UploadHelpers
  config.include ActiveSupport::Testing::TimeHelpers

  # rswag documentation specs: embed the actual JSON response as the example in swagger.yaml.
  config.after(:each, :operation) do |example|
    next unless example.metadata[:response].is_a?(Hash) && response&.media_type == 'application/json'

    example.metadata[:response][:content] = (example.metadata[:response][:content] || {}).deep_merge(
      'application/json' => { example: JSON.parse(response.body) }
    )
  end
end
