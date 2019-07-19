module Api
  module V1
    class GraphqlController < Api::V1::BaseApiController
      include GraphqlDoc

      skip_before_filter :authenticate_from_token!

      before_action :start_apollo_if_needed, only: [:create]
      before_action :authenticate_graphql_user, only: [:create]
      before_action :set_current_user, :load_context_team, :set_current_team, :set_timezone, :load_ability, :init_bot_events

      after_action :trigger_bot_events

      def create
        query_string = params[:query]
        context = { ability: @ability, file: request.params[:file] }
        query_variables = ensure_hash(params[:variables]) || {}
        query_variables = {} if query_variables == 'null'
        begin
          result = RelayOnRailsSchema.execute(query_string, variables: query_variables, context: context)
          render json: result
        rescue ActiveRecord::RecordInvalid, RuntimeError, ActiveRecord::RecordNotUnique, NameError, GraphQL::Batch::NestedError => e
          render json: parse_json_exception(e), status: 400
        rescue CheckPermissions::AccessDenied => e
          render json: format_error_message(e), status: 403
        rescue ActiveRecord::RecordNotFound => e
          render json: format_error_message(e), status: 404
        rescue ActiveRecord::StaleObjectError => e
          render json: format_error_message(e), status: 409
        end
      end

      protected

      # If the request wasn't `Content-Type: application/json`, parse the variables
      def ensure_hash(variables_param)
        return {} if variables_param.blank?
        variables_param.kind_of?(Hash) ? variables_param : JSON.parse(variables_param)
      end

      def parse_json_exception(e)
        json = nil
        begin
          error = JSON.parse(e.message)
          json = {
            error: error['message'],
            errors: [{
              message: error['message'],
              data: { code: error['code'] }.merge(error['data'])
            }],
            error_info: {
              code: error['code']
            }.merge(error['data'])
          }
        rescue
          json = format_error_message(e)
        end
        json
      end

      def format_error_message(e)
        {
          error: e.message,
          errors: [{ message: e.message }]
        }
      end

      private

      def authenticate_graphql_user
        params[:query].to_s.match(/^((query )|(mutation[^\{]*{\s*(resetPassword|changePassword|resendConfirmation|userDisconnectLoginAccount|)))/).nil? ? authenticate_user! : authenticate_user
      end

      def load_ability
        @ability = Ability.new if signed_in?
      end

      def set_current_user
        User.current = current_api_user if ApiKey.current.nil?
      end

      def load_context_team
        slug = request.params['team'] || request.headers['X-Check-Team']
        slug = URI.decode(slug) unless slug.blank?
        @context_team = Team.where(slug: slug).first unless slug.blank?
        Team.current = @context_team
      end

      def set_current_team
        if !current_api_user.nil? && !@context_team.nil? && current_api_user.is_member_of?(@context_team) && current_api_user.current_team_id != @context_team.id
          current_api_user.current_team_id = @context_team.id
          current_api_user.save!
        end
      end

      def set_timezone
        @context_timezone = request.headers['X-Timezone']
      end

      def start_apollo_if_needed
        if File.exist?('config/apollo-engine-proxy.json')
          port = JSON.parse(File.read('config/apollo-engine-proxy.json'))['frontends'][0]['port']
          if system('lsof', "-i:#{port}", out: '/dev/null')
            @started_apollo = false
            Rails.logger.info "[Apollo] [#{Time.now}] Already running, nothing to do."
          else
            Rails.logger.info "[Apollo] [#{Time.now}] Not running, starting..."
            ApolloTracing.start_proxy('config/apollo-engine-proxy.json')
            @started_apollo = true
          end
        end
      end

      def init_bot_events
        BotUser.init_event_queue
      end

      def trigger_bot_events
        BotUser.trigger_events
      end
    end
  end
end
