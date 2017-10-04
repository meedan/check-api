module Api
  module V1
    class GraphqlController < Api::V1::BaseApiController
      include GraphqlDoc

      skip_before_filter :authenticate_from_token!

      before_action :authenticate_graphql_user, only: [:create]
      before_action :set_current_user, :load_context_team, :set_current_team, :load_ability, :store_request

      def create
        query_string = params[:query]
        query_variables = ensure_hash(params[:variables]) || {}
        query_variables = {} if query_variables == 'null'
        debug = !!CONFIG['graphql_debug']
        begin
          query = GraphQL::Query.new(RelayOnRailsSchema, query_string, variables: query_variables, debug: debug, context: { ability: @ability, file: request.params[:file] })
          render json: query.result
        rescue ActiveRecord::RecordInvalid, RuntimeError, ActiveRecord::RecordNotUnique, NameError => e
          render json: { error: e.message }, status: 400
        rescue CheckPermissions::AccessDenied => e
          render json: { error: e.message }, status: 403
        rescue ActiveRecord::RecordNotFound => e
          render json: { error: e.message }, status: 404
        end
      end

      protected

      # If the request wasn't `Content-Type: application/json`, parse the variables
      def ensure_hash(variables_param)
        return {} if variables_param.blank?
        variables_param.kind_of?(Hash) ? variables_param : JSON.parse(variables_param)
      end

      private

      def authenticate_graphql_user
        params[:query].to_s.match(/^((query )|(mutation[^\{]*{\s*(reset|change)Password))/).nil? ? authenticate_user! : authenticate_user
      end

      def load_ability
        @ability = Ability.new if signed_in?
      end

      def set_current_user
        User.current = current_api_user if ApiKey.current.nil?
      end

      def load_context_team
        slug = request.params['team']
        @context_team = Team.where(slug: slug).first unless slug.blank?
        Team.current = @context_team
      end

      def set_current_team
        if !current_api_user.nil? && !@context_team.nil? && current_api_user.is_member_of?(@context_team) && current_api_user.current_team_id != @context_team.id
          current_api_user.current_team_id = @context_team.id
          current_api_user.save!
        end
      end

      def store_request
        RequestStore[:request] = request
      end
    end
  end
end
