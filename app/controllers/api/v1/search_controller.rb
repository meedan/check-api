module Api
  module V1
    class SearchController < Api::V1::BaseApiController
      include SearchDoc

      skip_before_filter :authenticate_from_token!

      def create
        query_string = params[:query]
        repository = Elasticsearch::Persistence::Repository.new
        repository.index = 'checkdesk_application_development_annotations'
        repository.type = 'annotation'
        result = repository.search(query: { query_string: {query: query_string}})
        render json: { result: result }
      end

    end
  end
end
