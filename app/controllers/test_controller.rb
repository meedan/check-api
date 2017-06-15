class TestController < ApplicationController
  before_filter :check_environment

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

  private

  def check_environment
    (render(text: 'Only available in test mode', status: 400) and return) unless Rails.env === 'test'
  end
end
