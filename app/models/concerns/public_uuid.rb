# Devices and sensors are addressed by a client-chosen identifier in API URLs.
# No dots (Rails treats "." in a path segment as a format separator) or slashes.
module PublicUuid
  extend ActiveSupport::Concern

  FORMAT = /\A[A-Za-z0-9][A-Za-z0-9_:-]{0,63}\z/

  included do
    validates :uuid, presence: true, uniqueness: true,
                     format: { with: FORMAT, message: "must be 1-64 letters, digits, '_', ':' or '-'", allow_blank: true }
  end
end
