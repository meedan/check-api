module Ah
  module Api
    module Greenday
      module V1
        class BaseController < ::Api::V1::BaseApiController
          skip_before_filter :authenticate_from_token!

          before_action :check_if_options_request
          before_action :authenticate_montage_user, unless: proc { request.options? }
          before_action :set_current_user, :set_current_team, :load_ability

          def ping
            render json: true, status: 200
          end

          private

          def authenticate_montage_user
            header = CONFIG['authorization_header'] || 'X-Token'
            token = request.headers[header].to_s
            user = User.where(token: token).last
            if user.nil?
              authenticate_api_user!
            else
              User.current = user
              sign_in(user, store: false)
            end
          end

          def set_current_user
            User.current = current_api_user
          end

          def set_current_team
            slug = request.params['team'] || request.headers['X-Check-Team']
            slug = URI.decode(slug) unless slug.blank?
            Team.current = Team.where(slug: slug).first
          end

          def load_ability
            @ability = Ability.new if signed_in?
          end

          def check_if_options_request
            if request.options?
              render json: true, status: 200
            end
          end
        end
      end
    end
  end
end
