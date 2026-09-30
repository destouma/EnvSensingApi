class Api::V1::SensorsController < Api::V1::BaseController
  before_action :require_read_scope!, only: [:index, :show]
  before_action :require_admin_scope!, only: :create

  # GET /api/v1/devices/:device_uuid/sensors
  def index
    device = Device.find_by!(uuid: params[:device_uuid])
    @sensors = device.sensors.includes(:device, :sensor_type).order(:id)
  end

  # GET /api/v1/sensors/:uuid
  def show
    @sensor = Sensor.includes(:device, :sensor_type).find_by!(uuid: params[:uuid])
  end

  # POST /api/v1/devices/:device_uuid/sensors
  def create
    device = Device.find_by!(uuid: params[:device_uuid])
    @sensor = device.sensors.new(params.permit(:uuid, :name, :description, :sensor_type_id))
    @sensor.save!
    render :show, status: :created
  end
end
