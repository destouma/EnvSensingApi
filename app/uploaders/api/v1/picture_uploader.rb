module Api
  module V1
    class PictureUploader < CarrierWave::Uploader::Base
      IMAGE_SIGNATURES = [
        "\xFF\xD8\xFF".b,         # JPEG
        "\x89PNG\r\n\x1A\n".b     # PNG
      ].freeze

      storage :file

      before :cache, :check_image_signature!

      # model is the uploading Device: each device gets its own directory,
      # so a device cannot overwrite another device's pictures.
      def store_dir
        Picture.storage_dir_for(model).to_s
      end

      def extension_allowlist
        %w(jpg jpeg png)
      end

      def size_range
        1..5.megabytes
      end

      private

      # The Content-Type header is client controlled, so check the file's magic bytes instead.
      def check_image_signature!(new_file)
        header = new_file.path ? File.binread(new_file.path, 8) : new_file.read.to_s.byteslice(0, 8)
        return if IMAGE_SIGNATURES.any? { |signature| header.to_s.b.start_with?(signature) }

        raise CarrierWave::IntegrityError, "file is not a JPEG or PNG image"
      end
    end
  end
end
