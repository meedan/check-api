require 'error_codes'

module Api
  module V1
    class BaseApiController < ApplicationController
      include BaseDoc

      before_filter :remove_empty_params_and_headers
      before_filter :set_custom_response_headers
      before_filter :authenticate_from_token!, except: [:me, :options]
      after_filter :set_access_headers
      # Verify payload for webhook methods
      # before_filter :verify_payload!

      respond_to :json

      def version
        name = "#{Rails.application.class.parent_name} v#{VERSION}"
        render_success 'version', name
      end

      def me
        header = CONFIG['authorization_header'] || 'X-Token'
        token = request.headers[header]
        user = nil
        source = nil
        
        if token
          user = User.where(token: token).last
          source = 'token'
        else
          user = current_api_user
          source = 'session' unless user.nil?
        end

        unless user.nil?
          user_json = user.as_json
          user_json[:source] = source
          user_json[:current_team] = user.current_team.as_json
          user_json[:current_team][:projects] = user.current_team.projects.as_json if user.current_team
          user = user_json
        end

        render_success 'user', user
      end

      # Needed for pre-flight check
      def options
        render text: ''
      end

      private

      def authenticate_from_token!
        header = CONFIG['authorization_header'] || 'X-Token'
        token = request.headers[header]
        key = ApiKey.where(access_token: token).where('expire_at > ?', Time.now).exists?
        (render_unauthorized and return false) unless key
      end

      # User token or session
      def authenticate_user!
        header = CONFIG['authorization_header'] || 'X-Token'
        token = request.headers[header].to_s
        user = User.where(token: token).last
        (token && user) ? sign_in(user, store: false) : authenticate_api_user!
      end

      def verify_payload!
        begin
          payload = request.raw_post
          if verify_signature(payload)
            @payload = JSON.parse(payload)
          else
            render_unauthorized and return
          end
        rescue
          render_error('Could not verify payload', 'UNKNOWN') and return
        end
      end

      def verify_signature(payload)
        signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), CONFIG['secret_token'].to_s, payload)
        Rack::Utils.secure_compare(signature, request.headers['X-Signature'].to_s)
      end
  
      def get_params
        params.reject{ |k, _v| ['id', 'action', 'controller', 'format'].include?(k) }
      end

      def remove_empty_params_and_headers
        params.reject!{ |_k, v| v.blank? }
        request.headers.each{ |k, v| request.headers[k] = nil if (k =~ /HTTP_/).present? && v.blank? }
      end

      def set_custom_response_headers
        response.headers['X-Build'] = BUILD
        response.headers['Accept'] ||= ApiConstraints.accept(1)
      end

      def set_access_headers
        headers['Access-Control-Allow-Headers'] = [CONFIG['authorization_header'], 'Content-Type', 'Accept'].join(',')
        headers['Access-Control-Allow-Credentials'] = 'true'
        headers['Access-Control-Allow-Origin'] = CONFIG['checkdesk_client']
      end
    end
  end
end
