module Api
  module V2
    # Parent controller for REST API
    class ResourceController < Api::V2::BaseApiController

      include JSONAPI::ActsAsResourceController

      skip_before_action :authenticate_from_token!
      before_action :authenticate_user!
      before_action :set_current_user

      def context
        { current_user: User.current, current_api_key: ApiKey.current }
      end

      private

      def set_current_user
        User.current = current_api_user if ApiKey.current.nil?
      end
    end
  end
end
