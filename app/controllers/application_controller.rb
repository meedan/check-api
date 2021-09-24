require 'error_codes'

class ApplicationController < ActionController::Base
  include HttpAcceptLanguage::AutoLocale

  protect_from_forgery with: :exception, prepend: true
  skip_before_action :verify_authenticity_token

  before_action :configure_permitted_parameters, if: :devise_controller?

  # app/controllers/application_controller.rb
  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.uuid
    payload[:user_id] = current_api_user.id if current_api_user
  end

  private

  def render_success(type = 'success', object = nil)
    json = { type: type }
    json[:data] = object unless object.nil?
    logger.info message: json, status: 200
    render json: json, status: 200
  end

  def render_error(message, code, status = 400)
    render json: { errors: [{
                     message: message,
                     code: LapisConstants::ErrorCodes::const_get(code),
                     data: {},
                   }],
                 },
                 status: status
    logger.error message: message, status: 400
  end

  def render_unauthorized
    render_error 'Unauthorized', 'UNAUTHORIZED', 401
    logger.warn message: 'unauthorized', status: 401
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt])
  end
end
