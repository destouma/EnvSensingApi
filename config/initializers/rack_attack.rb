# Rate limiting. Counters live in Rails.cache (file store by default, shared by Puma workers).
class Rack::Attack
  API_PATH = %r{\A/api/}.freeze

  # All devices behind one home router share a public IP, so the per-IP limit is
  # generous; the tighter limit is per token.
  throttle("api/ip", limit: 1000, period: 5.minutes) do |req|
    req.ip if req.path.match?(API_PATH)
  end

  throttle("api/token", limit: 300, period: 5.minutes) do |req|
    if req.path.match?(API_PATH)
      scheme, token = req.get_header("HTTP_AUTHORIZATION").to_s.split(" ", 2)
      # Key on a digest so raw tokens never end up in the cache.
      Digest::SHA256.hexdigest(token) if scheme&.casecmp?("Bearer") && token.present?
    end
  end

  # Slows down password guessing on the Basic auth protected admin.
  throttle("admin/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/admin")
  end

  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"]
    retry_after = match_data[:period] - (match_data[:epoch_time] % match_data[:period])
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [{ message: "Error: too many requests" }.to_json]
    ]
  end
end

# Specs that exercise throttling enable it explicitly.
Rack::Attack.enabled = !Rails.env.test?
