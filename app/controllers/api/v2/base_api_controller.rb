module Api
  module V2
    class BaseApiController < Api::V1::BaseApiController
      respond_to :json

      def version
        render json: { version: 2 }
      end

      def ping
        render plain: ''
      end

      # Needed for pre-flight check
      def options
        render plain: ''
      end
    end
  end
end
