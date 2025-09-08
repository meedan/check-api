require 'error_codes'

module Api
  module V1
    class GraphqlController < Api::V1::BaseApiController
      include GraphqlDoc

      skip_before_action :authenticate_from_token!

      before_action :authenticate_graphql_user, only: [:create, :batch]
      before_action :set_current_user, :load_context_team, :set_current_team, :update_last_active_at, :set_timezone, :load_ability, :init_bot_events

      after_action :trigger_bot_events

      def create
        parse_graphql_result do |context|
          query_string = params[:query]
          query_variables = prepare_query_variables(params[:variables])
          RelayOnRailsSchema.execute(query_string, variables: query_variables, context: context)
        end
      end

      def batch
        parse_graphql_result do |context|
          queries = params[:_json]&.map do |param|
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
          end unless queries.nil?
          results
        end
      end

      protected

      def parse_graphql_result
        log_graphql_activity
        context = { ability: @ability, file: parse_uploaded_files }
        @output = nil
        begin
          result = yield(context)
          @output = result
          render json: result

        # Mutations are not batched, so we can return errors in the root
        rescue ActiveRecord::RecordInvalid, RuntimeError, NameError => e
          @output = parse_json_exception(e)
          CheckSentry.notify(e)
          render json: @output, status: 400
        rescue ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique => e
          @output = format_error_message(e)
          render json: @output, status: 409
        rescue Check::TooManyRequestsError => e
          @output = format_error_message(e)
          render json: @output, status: 429
        end
      end

      def log_graphql_activity
        return if User.current.nil?

        uid = User.current.id
        user_name = User.current.name
        team = Team.current || User.current.current_team
        team = team.nil? ? '' : team.name
        role = User.current.role
        Rails.logger.info("[Graphql] Logging activity: uid: #{uid} user_name: #{user_name} team: #{team} role: #{role}")
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
          ActiveRecord::StaleObjectError => ::LapisConstants::ErrorCodes::CONFLICT,
          ActiveRecord::RecordNotUnique => ::LapisConstants::ErrorCodes::CONFLICT,
          ActiveRecord::RecordInvalid => ::LapisConstants::ErrorCodes::INVALID_VALUE
        }
        errors = []
        message = e.message.kind_of?(Array) ? e.message : [e.message]
        message.each do |m|
          data = e.is_a?(ActiveRecord::RecordInvalid) ? e.record.errors.to_hash : {}
          errors << {
            message: m,
            code: mapping[e.class] || ::LapisConstants::ErrorCodes::UNKNOWN,
            data: data,
          }
        end
        { errors: errors }
      end

      private

      def authenticate_graphql_user
        operation_def = get_operation_def(params[:query])
        safe_operation?(operation_def) ? authenticate_user : authenticate_user!
      end

      def get_operation_def(query_string)
        document = begin GraphQL.parse(query_string) rescue nil end
        document.definitions.find{|d| d.is_a?(GraphQL::Language::Nodes::OperationDefinition)} unless document.nil?
      end

      def safe_operation?(operation_def)
        return false if operation_def.nil?
        operation_type  = operation_def.operation_type.to_s    # "query" or "mutation"
        root_field_name = operation_def.selections.first.name  # first field, e.g. "me" or "resetPassword"
        case operation_type
        when 'mutation'
          safe_mutations = %w(resetPassword changePassword resendConfirmation userDisconnectLoginAccount)
          safe_mutations.include?(root_field_name)
        when 'query'
          root_field_name == 'me'
        else
          false
        end
      end

      def load_ability
        @ability = Ability.new if signed_in?
      end

      def set_current_user
        User.current = current_api_user if ApiKey.current.nil?
      end

      def load_context_team
        slug = request.params['team'] || request.headers['X-Check-Team']
        slug = CGI::unescape(slug) unless slug.blank?
        @context_team = Team.where(slug: slug).first unless slug.blank?
        Team.current = @context_team
      end

      def set_current_team
        if !current_api_user.nil? && !@context_team.nil? && current_api_user.is_member_of?(@context_team) && current_api_user.current_team_id != @context_team.id
          current_api_user.current_team_id = @context_team.id
          current_api_user.save
        end
      end

      def set_timezone
        @context_timezone = request.headers['X-Timezone']
      end

      def init_bot_events
        BotUser.init_event_queue
      end

      def trigger_bot_events
        BotUser.trigger_events
      end

      def update_last_active_at
        user = User.current
        if user
          now = Time.now
          yesterday = 1.day.ago.to_i
          user.update_column(:last_active_at, now) if user.last_active_at.to_i < yesterday
          # set last_active_at based on team
          unless @context_team.nil?
            tu = user.team_users.where(team_id: @context_team.id).last
            tu.update_column(:last_active_at, now) if tu.present? && tu.last_active_at.to_i < yesterday
          end
        end
      end
    end
  end
end
