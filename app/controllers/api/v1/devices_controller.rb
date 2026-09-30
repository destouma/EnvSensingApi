class Api::V1::DevicesController < Api::V1::BaseController
  before_action :require_read_scope!, only: :index
  before_action :require_admin_scope!, only: :create

  # GET /api/v1/devices
  # GET /api/v1/devices.json
  def index
    @devices = Device.all
  end

  def create
    dev = Device.where(uuid: params[:uuid]).first
    if dev
      render json: { message: "Error: duplicate device uuid" }, status: :bad_request
    else
      @device = Device.new()
      @device.name  = params[:name]
      @device.uuid = params[:uuid]
      @device.description = params[:description]
      # Saved in the same transaction as the device.
      device_token = @device.device_tokens.build(name: "initial")
      if @device.save!
        # The plaintext token is returned only here; flash it into the device firmware.
        render json: @device.as_json.merge(api_token: device_token.token), status: :ok
      else
        render json: { message: "Error: impossible to save device" }, status: :bad_request
      end
    end

  end

end
