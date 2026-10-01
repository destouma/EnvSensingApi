# Opaque bearer tokens: 256 random bits, shown once at creation, stored as a SHA-256 digest.
# A fast hash is enough because the token is high entropy (no dictionary to brute force),
# and it keeps per-request authentication cheap.
module TokenAuthenticatable
  extend ActiveSupport::Concern

  LAST_USED_RESOLUTION = 1.minute

  included do
    # Plaintext token, only available on the instance that generated it.
    attr_reader :token

    scope :active, -> { where(revoked_at: nil) }

    before_validation :generate_token, on: :create
    validates :token_digest, presence: true, uniqueness: true
  end

  class_methods do
    def token_prefix(prefix = nil)
      prefix ? @token_prefix = prefix : @token_prefix
    end

    def digest(token)
      Digest::SHA256.hexdigest(token.to_s)
    end

    def find_by_token(token)
      return if token.blank? || !token.start_with?(token_prefix)

      active.find_by(token_digest: digest(token))
    end
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  # Avoid a DB write on every request (devices post readings frequently).
  def touch_last_used!
    return if last_used_at && last_used_at > LAST_USED_RESOLUTION.ago

    update_column(:last_used_at, Time.current)
  end

  private

  def generate_token
    return if token_digest.present?

    @token = "#{self.class.token_prefix}#{SecureRandom.urlsafe_base64(32)}"
    self.token_digest = self.class.digest(@token)
  end
end
