class Api::V1::BaseController < ActionController::API
  # Raised for malformed query parameters (limit, cursor, dates).
  class BadRequest < StandardError; end

  # Request bodies are read from top-level fields, not wrapped under the controller name.
  wrap_parameters false

  # Every endpoint requires a token unless a controller opts out explicitly.
  # Devices authenticate with a DeviceToken, people and scripts with an ApiKey.
  before_action :authenticate!

  # Every error response has the same shape:
  #   { "error": { "code": "not_found", "message": "Sensor not found", "details": { ... } } }
  rescue_from ActiveRecord::RecordNotFound do |e|
    render_error :not_found, "not_found", "#{e.model || 'Record'} not found"
  end
  rescue_from ActiveRecord::RecordInvalid do |e|
    render_error :unprocessable_content, "validation_failed", "Validation failed", e.record.errors.to_hash
  end
  rescue_from ActiveRecord::RecordNotUnique do
    render_error :conflict, "conflict", "A record with the same identifier already exists"
  end
  rescue_from ActiveRecord::DeleteRestrictionError do |e|
    render_error :conflict, "conflict", e.message
  end
  rescue_from ActionController::ParameterMissing, BadRequest do |e|
    render_error :bad_request, "bad_request", e.message
  end
  rescue_from ActionDispatch::Http::Parameters::ParseError do
    render_error :bad_request, "bad_request", "Request body is not valid JSON"
  end

  attr_reader :current_device, :current_api_key

  private

  def authenticate!
    token = bearer_token
    if (device_token = DeviceToken.find_by_token(token))
      device_token.touch_last_used!
      @current_device = device_token.device
    elsif (api_key = ApiKey.find_by_token(token))
      api_key.touch_last_used!
      @current_api_key = api_key
    else
      response.headers["WWW-Authenticate"] = 'Bearer realm="env-sensing-api"'
      render_error :unauthorized, "unauthorized", "A valid bearer token is required"
    end
  end

  def require_device!
    render_forbidden unless current_device
  end

  def require_read_scope!
    render_forbidden unless current_api_key&.allows?(:read)
  end

  def require_admin_scope!
    render_forbidden unless current_api_key&.allows?(:admin)
  end

  def bearer_token
    scheme, token = request.authorization.to_s.split(" ", 2)
    token if scheme&.casecmp?("Bearer")
  end

  def render_forbidden
    render_error :forbidden, "forbidden", "This token is not allowed to use this endpoint"
  end

  def render_error(status, code, message, details = nil)
    error = { code: code, message: message }
    error[:details] = details if details.present?
    render json: { error: error }, status: status
  end
end
