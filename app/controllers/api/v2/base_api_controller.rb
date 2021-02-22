module Api
  module V2
    class BaseApiController < ApplicationController
      respond_to :json

      def version
        render json: { version: 2 }
      end

      def ping
        render text: ''
      end

      # Needed for pre-flight check
      def options
        render text: ''
      end
    end
  end
end
