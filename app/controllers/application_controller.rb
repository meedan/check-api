require 'error_codes'

class ApplicationController < ActionController::Base
  include HttpAcceptLanguage::AutoLocale

  protect_from_forgery with: :exception
  skip_before_filter :verify_authenticity_token

  private

  def render_success(type = 'success', object = nil)
    json = { type: type }
    json[:data] = object unless object.nil?
    render json: json, status: 200
    logger.info message: json, status: 200
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
