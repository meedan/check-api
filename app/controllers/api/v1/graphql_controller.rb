module Api
  module V1
    class GraphqlController < Api::V1::BaseApiController
      include GraphqlDoc
      
      skip_before_filter :authenticate_from_token!
      before_action :authenticate_user!, only: [:create], if: -> { params[:query].to_s.match(/^query About \{about/).nil? }
      
      after_filter :set_access_headers

      def create
        query_string = params[:query]
        query_variables = params[:variables] || {}
        query_variables = {} if query_variables == 'null'
        debug = !!CONFIG['graphql_debug']
        query = GraphQL::Query.new(RelayOnRailsSchema, query_string, variables: query_variables, debug: debug, context: { current_user: current_api_user })
        render json: query.result
      end

      def options
        render text: ''
      end

      private

      def set_access_headers
        headers['Access-Control-Allow-Headers'] = [CONFIG['authorization_header'], 'Content-Type'].join(',')
      end
    end
  end
end
