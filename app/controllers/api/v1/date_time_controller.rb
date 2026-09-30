class Api::V1::DateTimeController < Api::V1::BaseController
  # Public: devices may need the time before anything else, and it exposes no data.
  skip_before_action :authenticate!

  def current_date_time
    current_date_time = Time.now.utc
    render json: { current_date_time: current_date_time}
  end
end
