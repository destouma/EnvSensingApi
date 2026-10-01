class Api::V1::TimeController < Api::V1::BaseController
  # Public: devices may need the time before anything else, and it exposes no data.
  skip_before_action :authenticate!

  # GET /api/v1/time
  def show
    now = Time.current
    render json: { current_date_time: now.utc.iso8601(3), epoch: now.to_i }
  end
end
