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
        @picture = Picture.new();
        tmp = params[:file_name]
        @picture.sensor_id= sensor.id
        @picture.file_name = params[:file_name]
        @picture.file_url = "#{Rails.root}/storage/pictures/#{tmp}"
        if params[:sensor_date_time]
            @picture.date_time=params[:picture_date_time]
        else
          @picture.date_time=DateTime.now
        end
        @picture.save!
      else
        render json: { message: "Error: sensor not found" }, status: :bad_request
      end
    else
      render json: { message: "Error: no sensor" }, status: :bad_request
    end
  end

  def upload
    @file = params[:file]
    uploader = PictureUploader.new
    uploader.store!(@file)
  end

  def file
    picture= Picture.find(params[:id])
    send_file picture.file_url
  end

end