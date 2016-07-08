require 'error_codes'

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_filter :verify_authenticity_token

  private

  # Renderization methods

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

  # def render_unknown_error
  #   render_error 'Unknown error', 'UNKNOWN'
  # end

  # def render_invalid
  #   render_error 'Invalid value', 'INVALID_VALUE'
  # end

  # def render_parameters_missing
  #   render_error 'Parameters missing', 'MISSING_PARAMETERS'
  # end

  # def render_not_found
  #   render_error 'Id not found', 'ID_NOT_FOUND', 404
  # end

  # def render_not_implemented
  #   render json: { success: true, message: 'Not implemented yet' }, status: 200
  # end

  # def render_deleted
  #   render_error 'This object was deleted', 'ID_NOT_FOUND', 410
  # end
end
