require 'error_codes'

module Api
  module V1
    class GraphqlController < Api::V1::BaseApiController
      include GraphqlDoc

      skip_before_action :authenticate_from_token!

      before_action :start_apollo_if_needed, only: [:create, :batch]
      before_action :authenticate_graphql_user, only: [:create, :batch]
      before_action :set_current_user, :update_last_active_at, :load_context_team, :set_current_team, :set_timezone, :load_ability, :init_bot_events

      after_action :trigger_bot_events

      def create
        Honeycomb.add_field('graphql_query', params[:query]) unless CheckConfig.get('honeycomb_key').blank?
        parse_graphql_result do |context|
          query_string = params[:query]
          query_variables = prepare_query_variables(params[:variables])
          RelayOnRailsSchema.execute(query_string, variables: query_variables, context: context)
        end
      end

      def batch
        Honeycomb.add_field('graphql_query', params[:_json]) unless CheckConfig.get('honeycomb_key').blank?
        parse_graphql_result do |context|
          queries = params[:_json].map do |param|
            {
              query: param[:query],
              variables: prepare_query_variables(param[:variables]),
              context: context.merge({ id: param[:id] })
            }
          end
          results = []
          RelayOnRailsSchema.multiplex(queries).each do |result|
            results << {
              id: result.query.context[:id],
              payload: result.to_h
            }
          end
          results
        end
      end

      protected

      def parse_graphql_result
        context = { ability: @ability, file: parse_uploaded_files }
        @output = nil
        begin
          result = yield(context)
          @output = result
          render json: result

        # Mutations are not batched, so we can return errors in the root
        rescue ActiveRecord::RecordInvalid, RuntimeError, ActiveRecord::RecordNotUnique, NameError, GraphQL::Batch::NestedError => e
          @output = parse_json_exception(e)
          render json: @output, status: 400
        rescue ActiveRecord::StaleObjectError => e
          @output = format_error_message(e)
          render json: @output, status: 409
        end
      end

      def parse_uploaded_files
        file_param = request.params[:file]
        file = file_param
        @files = [file_param]
        if file_param.is_a?(Hash)
          file = []
          file_param.each do |key, value|
            file[key.to_i] = value
          end
          @files = file
        end
        file
      end

      def prepare_query_variables(vars)
        query_variables = ensure_hash(vars) || {}
        query_variables = {} if query_variables == 'null'
        query_variables
      end

      # If the request wasn't `Content-Type: application/json`, parse the variables
      def ensure_hash(variables_param)
        return {} if variables_param.blank?
        if !variables_param.kind_of?(Hash)
          variables_param = variables_param.to_json unless variables_param.kind_of?(String)
        end
        variables_param.kind_of?(Hash) ? variables_param : JSON.parse(variables_param)
      end

      def parse_json_exception(e)
        json = nil
        begin
          errors = []
          message = JSON.parse(e.message)
          message = message.kind_of?(Array) ? message : [message]
          message.each do |i|
            errors << {
              message: i['message'],
              code: i['code'],
              data: i['data'],
            }
          end
          json = { errors: errors }
        rescue
          json = format_error_message(e)
        end
        json
      end

      def format_error_message(e)
        mapping = {
          CheckPermissions::AccessDenied => ::LapisConstants::ErrorCodes::ID_NOT_FOUND,
          ActiveRecord::RecordNotFound => ::LapisConstants::ErrorCodes::ID_NOT_FOUND,
          ActiveRecord::StaleObjectError => ::LapisConstants::ErrorCodes::CONFLICT
        }
        errors = []
        message = e.message.kind_of?(Array) ? e.message : [e.message]
        message.each do |i|
          errors << {
            message: i,
            code: mapping[e.class] || ::LapisConstants::ErrorCodes::UNKNOWN,
            data: {},
          }
        end
        { errors: errors }
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

      def update_last_active_at
        user = User.current
        user.update_column(:last_active_at, Time.now) if user && user.last_active_at.to_i < Time.now.ago(1.day).to_i
      end
    end
  end
end
