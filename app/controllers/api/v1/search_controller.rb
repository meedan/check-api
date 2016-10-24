module Api
  module V1
    class SearchController < Api::V1::BaseApiController
      include SearchDoc

      skip_before_filter :authenticate_from_token!

      def create

      end

    end
  end
end
