require 'error_codes'

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_filter :verify_authenticity_token

  private

  def render_success(type = 'success', object = nil)
    json = { type: type }
    json[:data] = object unless object.nil?
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
  end

  def render_unauthorized
    render_error 'Unauthorized', 'UNAUTHORIZED', 401
  end
end
