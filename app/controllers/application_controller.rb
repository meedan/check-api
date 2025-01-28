require 'error_codes'
require 'tracing_service'

class ApplicationController < ActionController::Base
  include HttpAcceptLanguage::AutoLocale

  protect_from_forgery with: :exception, prepend: true
  skip_before_action :verify_authenticity_token

  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :add_info_to_trace

  # app/controllers/application_controller.rb
  def append_info_to_payload(payload)
    super
    payload[:request_id] = request.uuid
    payload[:user_id] = current_api_user.id if current_api_user
  end

  def add_info_to_trace
    user_id = current_api_user&.id
    team_id = current_api_user&.current_team_id
    api_key_id = ApiKey.current&.id

    CheckSentry.set_user_info(user_id, team_id: team_id, api_key_id: api_key_id)
    TracingService.add_attributes_to_current_span(
      'app.user.id' => user_id,
      'app.user.team_id' => team_id,
      'app.api_key_id' => api_key_id,
    )
  end

  private

  def render_success(type = 'success', object = nil, status = 200, errors = nil)
    json = { type: type }
    json[:data] = object unless object.nil?
    json[:errors] = errors unless errors.nil?
    logger.info message: json, status: status
    render json: json, status: status
  end

  def render_error(message, code, status = 400)
    render json: { errors: [{
                     message: message,
                     code: LapisConstants::ErrorCodes::const_get(code),
                     data: {},
                   }],
                 },
                 status: status
    logger.error message: message, status: status
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
