# :nocov:
class MediasController < ApplicationController
  before_action :set_media, only: [:show, :edit, :update, :destroy]

  def index
    @medias = Media.all
  end

  def show
  end

  def new
    @media = Media.new
  end

  def edit
  end

  def create
    @media = Media.new(media_params)

    respond_to do |format|
      if @media.save
        format.html { redirect_to @media, notice: 'Media was successfully created.' }
        format.json { render :show, status: :created, location: @media }
      else
        format.html { render :new }
        format.json { render json: @media.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @media.update(media_params)
        format.html { redirect_to @media, notice: 'Media was successfully updated.' }
        format.json { render :show, status: :ok, location: @media }
      else
        format.html { render :edit }
        format.json { render json: @media.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @media.destroy
    respond_to do |format|
      format.html { redirect_to medias_url, notice: 'Media was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def set_media
    @media = Media.find(params[:id])
  end

  def media_params
    params.fetch(:media, {})
  end
end
# :nocov:
