module Api
  module V1
    class GraphqlController < Api::V1::BaseApiController
      include GraphqlDoc
      
      skip_before_filter :authenticate_from_token!
      before_action :authenticate_user!, only: [:create], if: -> { params[:query].to_s.match(/^query About \{about/).nil? }
      before_action :load_context_team, :set_current_team

      def create
        query_string = params[:query]
        query_variables = params[:variables] || {}
        query_variables = {} if query_variables == 'null'
        debug = !!CONFIG['graphql_debug']
        begin
          query = GraphQL::Query.new(RelayOnRailsSchema, query_string, variables: query_variables, debug: debug, context: { current_user: current_api_user, context_team: @context_team, origin: request.headers['origin'] })
          render json: query.result
        rescue ActiveRecord::RecordInvalid, RuntimeError, ActiveRecord::RecordNotUnique => e
          render json: { error: e.message }, status: 400
        rescue CheckdeskPermissions::AccessDenied => e
          render json: { error: e.message }, status: 403
        rescue ActiveRecord::RecordNotFound => e
          render json: { error: e.message }, status: 404
        end
      end

      private

      def load_context_team
        @context_team = nil
        subdomain = Regexp.new(CONFIG['checkdesk_client']).match(request.headers['origin'])
        @context_team = Team.where(subdomain: subdomain[1]).first unless subdomain.nil?
        log = @context_team.nil? ? 'No context team' : "Context team is #{@context_team.name}"
        Rails.logger.info log
      end

      def set_current_team
        if !current_api_user.nil? && !@context_team.nil? && current_api_user.is_member_of?(@context_team) && current_api_user.current_team_id != @context_team.id
          current_api_user.current_team_id = @context_team.id
          current_api_user.save!
        end
      end
    end
  end
end
