class Api::V1::SensorReadingsController < Api::V1::BaseController
  before_action :require_read_scope!, only: :index
  before_action :require_device!, only: :create

  # GET /api/v1/sensor_readings
  # GET /api/v1/sensor_readings.json
  # GET /api/v1/sensor_readings.json?sensor_uuid=xxx
  def index
    if params[:sensor_uuid]
      sensor = Sensor.where(uuid: params[:sensor_uuid]).first
      if sensor
        @sensor_readings = SensorReading.where(sensor_id: sensor.id)
      else
        render json: { message: "Error: sensor not found" }, status: :bad_request
      end
    else
      # @sensor_readings = SensorReading.all
      render json: { message: "Error: no sensor" }, status: :bad_request
    end
  end

  # POST /api/v1/sensor_readings
  # POST /api/v1/sensor_readings.json
  def create
    # A device may only post readings for its own sensors.
    sensor = current_device.sensors.where(uuid: params[:sensor_uuid]).first
    if sensor
      @sensor_reading = SensorReading.new()
      @sensor_reading.sensorvalue  = params[:sensor_value]
      @sensor_reading.sensor_id = sensor.id
      if params[:sensor_date_time]
        @sensor_reading.date_time=params[:sensor_date_time]
      else
        @sensor_reading.date_time=DateTime.now
      end
      if @sensor_reading.save!
        render json: @sensor_reading, status: :ok
      else
        render json: { message: "Error: impossible to save reading" }, status: :bad_request
      end
    else
      render json: { message: "Error: sensor not found" }, status: :bad_request
    end
  end

end
