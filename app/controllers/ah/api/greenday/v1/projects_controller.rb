class Ah::Api::Greenday::V1::ProjectsController < Ah::Api::Greenday::V1::BaseController
  before_action :check_if_team_exists, only: [:show, :collection, :batch_create, :video, :comments, :show_video]
  before_action :check_if_project_media_exists, only: [:comments, :show_video]

  def index
    items = []
    user = User.current
    unless user.nil?
      user.team_users.each do |team_user|
        team_user = team_user.extend(Montage::ProjectUser)
        team = team_user.team.extend(Montage::Project)
        items << team.team_as_montage_project_json(team_user)
      end
    end
    json = {
      is_list: true,
      items: items
    }
    render json: json, status: 200
  end

  def create
    data = JSON.parse(request.raw_post)
    team = Team.new
    team.name = data['name']
    team.description = data['description']
    team.slug = Team.slug_from_name(data['name']) + '-' + Time.now.to_i.to_s
    team.save!
    # FIXME: Montage supports videos without a collection, but Check doesn't support project medias without a project... that's why we create a project by default
    Project.create!(title: team.name, team_id: team.id)
    team = team.extend(Montage::Project)
    team_user = TeamUser.where(team_id: team.id, user_id: User.current&.id).last.extend(Montage::ProjectUser)
    json = team.team_as_montage_project_json(team_user)
    render json: json, status: 200
  end

  def batch_create
    return if @team.nil?
    data = JSON.parse(request.raw_post)
    items = []
    videos = []
    # FIXME: Montage supports videos without a collection, but Check doesn't support project medias without a project... that's why we get one by default
    project = @team.projects.first || Project.create!(title: @team.name, team_id: @team.id)
    data['youtube_ids'].each do |id|
      url = "https://www.youtube.com/watch?v=#{id}"
      begin
        pm = ProjectMedia.create! url: url, project_id: project.id
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

  def video
    return if @team.nil?
    items = []
    pmids = []
    @team.video(params[:collection_id].to_i).each do |pm|
      next if pmids.include?(pm.id)
      items << pm.extend(Montage::Video).project_media_as_montage_video_json
      pmids << pm.id
    end
    json = {
      is_list: true,
      items: items,
    }
    render json: json, status: 200
  end

  def show
    return if @team.nil?
    team_user = TeamUser.where(team_id: @team.id, user_id: User.current&.id).last.extend(Montage::ProjectUser)
    json = @team.team_as_montage_project_json(team_user)
    render json: json, status: 200
  end

  def collection
    return if @team.nil?
    json = nil

    if request.get?
      items = []
      @team.projects.each do |project|
        project = project.extend(Montage::Collection)
        items << project.project_as_montage_collection_json
      end
      json = {
        is_list: true,
        items: items
      }
    elsif request.post?
      data = JSON.parse(request.raw_post)
      project = Project.create!(title: data['name'], team_id: data['project_id'])
      project = project.extend(Montage::Collection)
      json = project.project_as_montage_collection_json
    end

    render json: json, status: 200
  end

  def comments
    return if @team.nil?
    return if @pms.empty?

    items = []

    if request.get?
      Comment.where(annotated_type: 'ProjectMedia', annotated_id: @pms.map(&:id), annotation_type: 'comment').each do |comment|
        comment = comment.extend(Montage::Comment)
        items << comment.comment_as_montage_comment_json
      end
    elsif request.post?
      data = JSON.parse(request.raw_post)
      @pms.each do |pm|
        comment = Comment.new
        comment = comment.extend(Montage::Comment)
        comment.annotated = pm
        comment.text = data['text']
        comment.start_seconds = data['start_seconds']
        comment.save!
        items << comment.comment_as_montage_comment_json
      end
    end

    json = {
      is_list: true,
      items: items
    }

    render json: json, status: 200
  end

  def show_video
    return if @team.nil?
    return if @pms.empty?
    json = @pms.first.extend(Montage::Video).project_media_as_montage_video_json
    render json: json, status: 200
  end

  private

  def check_if_team_exists
    id = params[:id]
    @team = Team.where(id: id).last.extend(Montage::Project)
    render(text: 'Not Found', status: 404) if @team.nil?
  end

  def check_if_project_media_exists
    @team = Team.where(id: params[:id]).last.extend(Montage::Project)
    render(text: 'Not Found', status: 404) and return if @team.nil?
    @pms = ProjectMedia.get_all_by_youtube_id(params[:youtube_id], @team.id).collect{ |pm| pm.extend(Montage::Video) }
    render(text: 'Not Found', status: 404) and return if @pms.empty?
  end
end
