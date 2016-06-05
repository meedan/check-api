require 'error_codes'

module Api
  module V1
    class BaseApiController < ApplicationController
      include BaseDoc

      before_filter :remove_empty_params_and_headers
      before_filter :set_custom_response_headers
      before_filter :authenticate_from_token!
      # Verify payload for webhook methods
      # before_filter :verify_payload!

      respond_to :json

      def version
        name = "#{Rails.application.class.parent_name} v#{VERSION}"
        render_success 'version', name
      end

      private

      def authenticate_from_token!
        header = CONFIG['authorization_header'] || 'X-Token'
        token = request.headers[header]
        key = ApiKey.where(access_token: token).where('expire_at > ?', Time.now).exists?
        (render_unauthorized and return false) unless key
      end

      def verify_payload!
        begin
          payload = request.raw_post
          if verify_signature(payload)
            @payload = JSON.parse(payload)
          else
            render_unauthorized and return
          end
        rescue Exception => e
          render_error(e.message, 'UNKNOWN') and return
        end
      end

      def verify_signature(payload)
        signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'].to_s, payload)
        Rack::Utils.secure_compare(signature, request.headers['X-Signature'].to_s)
      end
  
      def get_params
        params.reject{ |k, v| ['id', 'action', 'controller', 'format'].include?(k) }
      end

      def remove_empty_params_and_headers
        params.reject!{ |k, v| v.blank? }
        request.headers.each{ |k, v| request.headers[k] = nil if (k =~ /HTTP_/).present? && v.blank? }
      end

      def set_custom_response_headers
        response.headers['X-Build'] = BUILD
        response.headers['Accept'] ||= ApiConstraints.accept(1)
      end

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
      #   render json: { success: true, message: 'TODO' }, status: 200
      # end

      # def render_deleted
      #   render_error 'This object was deleted', 'ID_NOT_FOUND', 410
      # end
    end
  end
end
