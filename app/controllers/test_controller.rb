class TestController < ApplicationController
  before_filter :check_environment

  def confirm_user
    user = User.where(email: params[:email]).last
    unless user.nil?
      user.confirm
    end
    render text: 'OK'
  end

  private

  def check_environment
    (render(text: 'Only available in test mode', status: 400) and return) unless Rails.env === 'test'
  end
end
