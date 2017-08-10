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

  private

  def check_environment
    (render(text: 'Only available in test mode', status: 400) and return) unless Rails.env === 'test'
  end
end
