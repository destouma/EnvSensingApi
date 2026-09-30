class Api::V1::ReadingsController < Api::V1::BaseController
  include KeysetPagination

  MAX_BATCH_SIZE = 100

  before_action :require_read_scope!, only: :index
  before_action :require_device!, only: [ :create, :batch ]

  # GET /api/v1/sensors/:sensor_uuid/readings
  def index
    @sensor = Sensor.includes(:device, :sensor_type).find_by!(uuid: params[:sensor_uuid])
    @readings, @next_cursor = paginate(@sensor.sensor_readings)
  end

  # POST /api/v1/sensors/:sensor_uuid/readings  { "value": 2150, "date_time": "..." }
  def create
    # A device may only post readings for its own sensors; others are reported as not found.
    sensor = current_device.sensors.find_by!(uuid: params[:sensor_uuid])
    @reading = sensor.sensor_readings.create!(params.permit(:value, :date_time))
    render :show, status: :created
  end

  # POST /api/v1/readings  { "readings": [{ "sensor_uuid": "...", "value": 2150, "date_time": "..." }, ...] }
  # One request per measurement cycle (TLS handshakes are expensive on microcontrollers).
  # All or nothing: if any reading is invalid, none is stored.
  def batch
    items = params.expect(readings: [ [ :sensor_uuid, :value, :date_time ] ])
    raise BadRequest, "readings must contain 1 to #{MAX_BATCH_SIZE} items" unless items.size.between?(1, MAX_BATCH_SIZE)

    sensors = current_device.sensors.where(uuid: items.map { |item| item[:sensor_uuid] }).index_by(&:uuid)
    @readings = items.map do |item|
      SensorReading.new(sensor: sensors[item[:sensor_uuid]], value: item[:value], date_time: item[:date_time])
    end

    errors = batch_errors(items, sensors)
    return render_error(:unprocessable_content, "validation_failed", "Validation failed", errors) if errors.any?

    SensorReading.transaction { @readings.each(&:save!) }
    render :batch, status: :created
  end

  private

  def batch_errors(items, sensors)
    errors = {}
    @readings.each_with_index do |reading, index|
      if sensors[items[index][:sensor_uuid]].nil?
        errors["readings[#{index}].sensor_uuid"] = [ "sensor not found" ]
      elsif reading.invalid?
        reading.errors.each { |error| (errors["readings[#{index}].#{error.attribute}"] ||= []) << error.message }
      end
    end
    errors
  end
end
