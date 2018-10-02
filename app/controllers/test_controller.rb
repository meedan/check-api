require 'sample_data'

class TestController < ApplicationController
  before_filter :check_environment

  include SampleData

  def confirm_user
    user = User.where(email: params[:email]).last
    unless user.nil?
      user.skip_check_ability = true
      user.confirm
    end
    render text: 'OK'
  end

  def make_team_public
    team = Team.where(slug: params[:slug]).last
    unless team.nil?
      team.private = false
      team.save!
    end
    render text: 'OK'
  end

  def new_user
    u = create_user params
    u.accept_terms = true
    render_success 'user', u
  end

  def create_team_project_and_two_users
    t = create_team
    u1 = create_user
    u2 = create_user
    u1.accept_terms = true
    u2.accept_terms = true
    create_team_user team: t, user: u1, role: 'owner'
    create_team_user team: t, user: u2, role: 'contributor'
    pr = create_project team: t, current_user: u1
    ret = {:team =>t, :user1 => u1, :user2 => u2, :project => pr}

    render_success 'team_users', ret
  end

  def new_team
    user = User.where(email: params[:email]).last
    User.current = user
    t = create_team params
    User.current = nil
    render_success 'team', t
  end

  def update_suggested_tags
    t = Team.find(params[:team_id])
    params[:tags].to_s.split(',').each{ |text| TagText.create(text: text, team_id: params[:team_id]) }
    t.save
    render_success 'team', t
  end

  def new_project
    Team.current = Team.find(params[:team_id])
    p = create_project params
    Team.current = nil
    render_success 'project', p
  end

  def new_session
    user = User.where(email: params[:email]).last
    User.current = user
    request.env['devise.mapping'] = Devise.mappings[:api_user]
    sign_in user
    User.current = nil
    render_success 'user', current_api_user
  end

  def new_claim
    new_media 'claim'
  end

  def new_link
    new_media 'link'
  end

  def new_source
    Team.current = Team.find(params[:team_id])
    user = User.where(email: params[:email]).last
    User.current = user
    ps = ProjectSource.new
    ps.project_id = params[:project_id]
    ps.name = params[:name]
    ps.url = params[:url]
    ps.save!
    User.current = nil
    Team.current = nil
    render_success 'project_source', ps
  end

  def media_status
    pm = ProjectMedia.find(params[:pm_id])
    s = pm.last_status_obj
    s.status = params[:status]
    s.save!
    render_success 'project_media', pm
  end

  def new_media_tag
    user = User.where(email: params[:email]).last
    pm = ProjectMedia.find(params[:pm_id])
    tag = create_tag tag: params[:tag], annotated: pm, annotator: user
    pm.save!
    render_success 'project_media', pm
  end

  def new_task
    user = User.where(email: params[:email]).last
    pm = ProjectMedia.find(params[:pm_id])
    t = create_task({ annotated: pm, annotator: user }.merge(params))
    render_success 'task', t
  end

  def new_api_key
    if params[:access_token]
      a = ApiKey.where(access_token: params[:access_token]).last
      unless a.nil?
        render_success 'api_key', a
        return true
      end
    end
    a = create_api_key(params)
    params.each do |key, value|
      a.send("#{key}=", value) if a.respond_to?("#{key}=")
    end
    a.save!
    render_success 'api_key', a
  end

  def get
    klass = params[:class].camelize
    obj = klass.constantize.find(params[:id])
    ret = {}
    params[:fields].split(',').each do |field|
      ret[field] = obj.send(field) if obj.respond_to?(field)
    end
    render_success params[:class], ret
  end

  def new_bot
    b = create_team_bot name: 'Testing Bot', approved: true
    render_success 'bot', b
  end

  def archive_project
    p = Project.find(params[:project_id])
    p.archived = true
    p.save!
    render_success 'project', p
  end

  protected

  def new_media(type)
    Team.current = Team.find(params[:team_id])
    user = params[:email].blank? ? nil : User.where(email: params[:email]).last
    User.current = user
    pm = ProjectMedia.new
    pm.project_id = params[:project_id]
    pm.quote = params[:quote] if type == 'claim'
    pm.url = params[:url] if type == 'link'
    pm.save!
    User.current = nil
    Team.current = nil
    render_success 'project_media', pm
  end

  private

  def check_environment
    (render(text: 'Only available in test mode', status: 400) and return) unless Rails.env === 'test'
  end
end
