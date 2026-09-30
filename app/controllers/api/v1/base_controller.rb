class Api::V1::BaseController < ApplicationController
  # Every endpoint requires a token unless a controller opts out explicitly.
  # Devices authenticate with a DeviceToken, people and scripts with an ApiKey.
  before_action :authenticate!

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
      render_unauthorized
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

  def render_unauthorized
    response.headers["WWW-Authenticate"] = 'Bearer realm="env-sensing-api"'
    render json: { message: "Error: unauthorized" }, status: :unauthorized
  end

  def render_forbidden
    render json: { message: "Error: forbidden" }, status: :forbidden
  end
end
