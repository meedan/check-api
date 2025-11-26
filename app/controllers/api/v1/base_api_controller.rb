require 'error_codes'

module Api
  module V1
    class BaseApiController < ApplicationController
      include BaseDoc

      before_action :remove_empty_params_and_headers
      before_action :set_custom_response_headers
      before_action :authenticate_from_token!, except: [:me, :options, :log, :ping]
      before_action :authenticate_user!, only: [:log]
      before_action :set_paper_trail_whodunnit, :store_request

      respond_to :json

      def version
        name = "#{Rails.application.class.module_parent_name} v#{VERSION}"
        render_success 'version', name
      end

      def ping
        render_success
      end

      def me
        header = CheckConfig.get('authorization_header', 'X-Token')
        token = request.headers[header]

        message = render_error_message
        unless message.blank?
          render_error(message, 'UNKNOWN') and return
        end

        if token
          render_user User.find_with_token(token), 'token'
        else
          render_user current_api_user, 'session'
        end
      end

      def log
        team = ''
        role = ''
        user_name = ''
        uid = 0
        unless User.current.nil?
          uid = User.current.id
          user_name = User.current.name
          team = Team.current || User.current.current_team
          team = team.nil? ? '' : team.name
          role = User.current.role
        end
        json = params.merge({ source: 'client', uid: uid, user_name: user_name, team: team, role: role, user_agent: request.user_agent })
        Rails.logger.info(json)
        render_success 'log', json
      end

      # Needed for pre-flight check
      def options
        render plain: ''
      end

      private

      def render_error_message
        message = ''
        if session['check.error']
          message = session['check.error']
          reset_session
        elsif session['check.warning']
          message = session['check.warning']
          session.delete('check.warning')
        end
        message
      end

      def render_user(user = nil, source = nil)
        unless user.nil?
          user = user.as_json
          user[:source] = source
        end

        render_success 'user', user
      end

      def authenticate_from_token!
        header = CheckConfig.get('authorization_header', 'X-Token')
        token = request.headers[header]
        @key = ApiKey.where(access_token: token).where('team_id IS NOT NULL').where('expire_at > ?', Time.now).first
        (render_unauthorized and return false) if @key.nil?
      end

      # User token or session
      def authenticate_user!
        identify_user(true)
      end

      def authenticate_user
        identify_user(false)
      end

      def identify_user(mandatory)
        header = CheckConfig.get('authorization_header', 'X-Token')
        token = request.headers[header].to_s
        key = ApiKey.where(access_token: token).where('team_id IS NOT NULL').where('expire_at > ?', Time.now).first
        if key.nil?
          ApiKey.current = nil
          user = User.find_with_token(token)
          User.current = user
          (!token.blank? && user) ? sign_in(user, store: false) : (authenticate_api_user! if mandatory)
        else
          # Update last_active_at for ApiKey
          key.update_column(:last_active_at, Time.now)
          User.current = key.bot_user
          ApiKey.current = key
        end
      end

      def remove_empty_params_and_headers
        params.reject!{ |_k, v| v.blank? }
        request.headers.each{ |k, v| request.headers[k] = nil if (k =~ /HTTP_/).present? && v.blank? }
      end

      def set_custom_response_headers
        response.headers['X-Build'] = BUILD
        response.headers['Accept'] ||= ApiConstraints.accept(1)
      end

      def user_for_paper_trail
        current_api_user.id unless current_api_user.nil?
      end

      def store_request
        RequestStore[:request] = request
      end
    end
  end
end
