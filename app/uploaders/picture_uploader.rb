class PictureUploader < CarrierWave::Uploader::Base
  IMAGE_SIGNATURES = [
    "\xFF\xD8\xFF".b,         # JPEG
    "\x89PNG\r\n\x1A\n".b     # PNG
  ].freeze

  storage :file

  before :cache, :check_image_signature!

  # model is the Picture: each device gets its own directory.
  def store_dir
    Picture.storage_dir_for(model.sensor.device).to_s
  end

  # CarrierWave caches uploads under public/uploads/tmp by default, which the web server
  # would serve. Keep the cache out of public/ and move (not copy) files so none are left behind.
  def cache_dir
    Rails.root.join("tmp/uploads").to_s
  end

  def move_to_cache
    true
  end

  def move_to_store
    true
  end

  def extension_allowlist
    %w[jpg jpeg png]
  end

  def size_range
    1..5.megabytes
  end

  # Server generated name: clients cannot choose, guess or overwrite stored file names.
  def filename
    "#{secure_token}.#{file.extension.downcase}" if original_filename.present?
  end

  private

  def secure_token
    ivar = "@#{mounted_as}_secure_token"
    model.instance_variable_get(ivar) || model.instance_variable_set(ivar, SecureRandom.uuid)
  end

  # The Content-Type header is client controlled, so check the file's magic bytes instead.
  def check_image_signature!(new_file)
    header = new_file.path ? File.binread(new_file.path, 8) : new_file.read.to_s.byteslice(0, 8)
    return if IMAGE_SIGNATURES.any? { |signature| header.to_s.b.start_with?(signature) }

    raise CarrierWave::IntegrityError, "file is not a JPEG or PNG image"
  end
end
