require 'error_codes'

class ApplicationController < ActionController::Base
  include HttpAcceptLanguage::AutoLocale

  protect_from_forgery with: :exception
  skip_before_filter :verify_authenticity_token

  rescue_from CanCan::AccessDenied do |exception|
    team = Team.current ? Team.current.id : 'empty'
    logger.warn message: "Access denied on #{exception.action} #{exception.subject} - User ID '#{current_api_user.id}' - Is admin? '#{current_api_user.is_admin?}' - Team: '#{team}'"
    redirect_to '/403.html'
  end

  def authenticated?
    if signed_in?
      User.current = current_api_user
      Team.current = nil
    else
      redirect_to('/') unless signed_in?
    end
  end

  private

  def render_success(type = 'success', object = nil)
    json = { type: type }
    json[:data] = object unless object.nil?
    logger.info message: json, status: 200
    render json: json, status: 200
  end

  def render_error(message, code, status = 400)
    render json: { type: 'error',
                   data: {
                     message: message,
                     code: LapisConstants::ErrorCodes::const_get(code)
                   }
                 },
                 status: status
    logger.error message: message, status: 400
  end

  def render_unauthorized
    render_error 'Unauthorized', 'UNAUTHORIZED', 401
    logger.warn message: 'unauthorized', status: 401
  end
end
