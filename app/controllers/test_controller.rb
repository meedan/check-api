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
    render_success 'user', u
  end

  def new_team
    user = User.where(email: params[:email]).last
    User.current = user
    t = create_team params
    User.current = nil
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

  protected

  def new_media(type)
    Team.current = Team.find(params[:team_id])
    user = User.where(email: params[:email]).last
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
