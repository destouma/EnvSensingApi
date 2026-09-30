class Api::V1::PicturesController < ApplicationController

  def index
    if params[:sensor_uuid]
      sensor = Sensor.where(uuid: params[:sensor_uuid]).first
      if sensor
        @pictures = Picture.where(sensor_id: sensor.id)
      else
        render json: { message: "Error: sensor not found" }, status: :bad_request
      end
    else
      render json: { message: "Error: no sensor" }, status: :bad_request
    end
  end

  def create
    if params[:sensor_uuid]
      sensor = Sensor.where(uuid: params[:sensor_uuid]).first
      if sensor
        @picture = Picture.new
        @picture.sensor_id = sensor.id
        @picture.file_name = params[:file_name]
        # sensor_date_time is still accepted for clients built against the old (buggy) parameter name
        date_time = params[:picture_date_time] || params[:sensor_date_time]
        @picture.date_time = date_time || DateTime.now
        unless @picture.save
          render json: { message: "Error: #{@picture.errors.full_messages.to_sentence}" }, status: :unprocessable_entity
        end
      else
        render json: { message: "Error: sensor not found" }, status: :bad_request
      end
    else
      render json: { message: "Error: no sensor" }, status: :bad_request
    end
  end

  def upload
    uploader = Api::V1::PictureUploader.new
    uploader.store!(params.require(:file))
  rescue CarrierWave::IntegrityError => e
    render json: { message: "Error: #{e.message}" }, status: :unprocessable_entity
  end

  def file
    picture = Picture.find(params[:id])
    path = picture.file_path
    if path
      send_file path, disposition: :inline
    else
      render json: { message: "Error: file not found" }, status: :not_found
    end
  end

end
