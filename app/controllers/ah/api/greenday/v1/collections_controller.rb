class Ah::Api::Greenday::V1::CollectionsController < Ah::Api::Greenday::V1::BaseController
  before_action :check_if_project_exists, only: [:update, :show, :add_batch]

  def update
    return if @project.nil?
    data = JSON.parse(request.raw_post)
    @project.title = data['name'] unless data['name'].blank?
    @project.save!
    json = @project.project_as_montage_collection_json
    render json: json, status: 200
  end

  def show
    return if @project.nil?
    json = @project.project_as_montage_collection_json
    render json: json, status: 200
  end

  def add_batch
    return if @project.nil?
    data = JSON.parse(request.raw_post)
    items = []
    videos = []
    default_project = @project.team.projects.first
    data['youtube_ids'].each do |id|
      url = "https://www.youtube.com/watch?v=#{id}"
      begin
        pm = ProjectMedia.joins(:media).where('medias.url' => url).where(project_id: default_project.id).last
        pm.project_id = @project.id
        pm.save!
        items << {
          msg: 'ok',
          success: true,
          youtube_id: id
        }
        videos << pm.extend(Montage::Video).project_media_as_montage_video_json
      rescue StandardError => e
        items << {
          mgs: e.message,
          success: false,
          youtube_id: id
        }
      end
    end
    json = {
      is_list: true,
      items: items,
      videos: videos
    }
    render json: json, status: 200
  end

  private

  def check_if_project_exists
    @project = Project.where(id: params['collection_id'], team_id: params['project_id']).last.extend(Montage::Collection)
    render(text: 'Not Found', status: 404) if @project.nil?
  end
end
