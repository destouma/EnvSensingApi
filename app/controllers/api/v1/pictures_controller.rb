class Api::V1::PicturesController < Api::V1::BaseController
  include KeysetPagination

  before_action :require_read_scope!, only: [ :index, :file ]
  before_action :require_device!, only: :create

  # GET /api/v1/sensors/:sensor_uuid/pictures
  def index
    @sensor = Sensor.includes(:device, :sensor_type).find_by!(uuid: params[:sensor_uuid])
    @pictures, @next_cursor = paginate(@sensor.pictures)
  end

  # POST /api/v1/sensors/:sensor_uuid/pictures  (multipart/form-data: file, date_time)
  def create
    # A device may only add pictures to its own sensors; others are reported as not found.
    sensor = current_device.sensors.find_by!(uuid: params[:sensor_uuid])
    file = params.require(:file)
    # CarrierWave treats a String as a local file path: only accept an actual upload.
    raise BadRequest, "file must be a multipart file upload" unless file.is_a?(ActionDispatch::Http::UploadedFile)

    @picture = sensor.pictures.create!(image: file, date_time: params[:date_time])
    render :show, status: :created
  end

  # GET /api/v1/pictures/:id/file
  def file
    picture = Picture.includes(sensor: :device).find(params[:id])
    path = picture.file_path
    return render_error(:not_found, "not_found", "Picture file not found") unless path

    send_file path, type: Rack::Mime.mime_type(File.extname(path), "application/octet-stream"), disposition: :inline
  end
end
