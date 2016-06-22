class MediasController < ApplicationController
  before_action :set_media, only: [:show, :edit, :update, :destroy]

  # GET /medias
  # GET /medias.json
  def index
    @medias = Media.all
  end

  # GET /medias/1
  # GET /medias/1.json
  def show
  end

  # GET /medias/new
  def new
    @media = Media.new
  end

  # GET /medias/1/edit
  def edit
  end

  # POST /medias
  # POST /medias.json
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

  # PATCH/PUT /medias/1
  # PATCH/PUT /medias/1.json
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

  # DELETE /medias/1
  # DELETE /medias/1.json
  def destroy
    @media.destroy
    respond_to do |format|
      format.html { redirect_to medias_url, notice: 'Media was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_media
      @media = Media.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def media_params
      params.fetch(:media, {})
    end
end
