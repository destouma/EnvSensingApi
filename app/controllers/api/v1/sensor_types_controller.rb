class Api::V1::SensorTypesController < Api::V1::BaseController
  before_action :require_read_scope!

  # GET /api/v1/sensor_types
  def index
    @sensor_types = SensorType.order(:id)
  end
end
