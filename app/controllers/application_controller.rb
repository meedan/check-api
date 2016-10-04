require 'error_codes'

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_filter :verify_authenticity_token

  after_filter :set_access_headers

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

  def set_access_headers
    allowed_headers = [CONFIG['authorization_header'], 'Content-Type', 'Accept', 'X-Checkdesk-Context-Team'].join(',')
    origin = Regexp.new(CONFIG['checkdesk_client']).match(request.headers['origin']).nil? ? 'localhost' : request.headers['origin']
    custom_headers = {
      'Access-Control-Allow-Headers' => allowed_headers,
      'Access-Control-Allow-Credentials' => 'true',
      'Access-Control-Request-Method' => '*',
      'Access-Control-Allow-Methods' => 'GET,POST,DELETE,OPTIONS',
      'Access-Control-Allow-Origin' => origin 
    }
    headers.merge! custom_headers
  end
end
