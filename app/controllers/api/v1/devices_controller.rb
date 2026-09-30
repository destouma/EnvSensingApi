class Api::V1::DevicesController < Api::V1::BaseController
  before_action :require_read_scope!, only: [ :index, :show ]
  before_action :require_admin_scope!, only: :create

  # GET /api/v1/devices
  def index
    @devices = Device.includes(sensors: :sensor_type).order(:id)
  end

  # GET /api/v1/devices/:uuid
  def show
    @device = Device.includes(sensors: :sensor_type).find_by!(uuid: params[:uuid])
  end

  # POST /api/v1/devices
  def create
    @device = Device.new(params.permit(:uuid, :name, :description))
    # Saved in the same transaction as the device; its plaintext token is returned only in this response.
    @device_token = @device.device_tokens.build(name: "initial")
    @device.save!
    render :show, status: :created
  end
end
