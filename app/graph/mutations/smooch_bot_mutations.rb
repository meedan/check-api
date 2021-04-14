module SmoochBotMutations
  AddSlackChannelUrl = GraphQL::Relay::Mutation.define do
    name 'SmoochBotAddSlackChannelUrl'

    input_field :id, !types.String
    input_field :set_fields, !types.String

    return_field :success, types.Boolean
    return_field :annotation, AnnotationType

    resolve -> (_root, inputs, _ctx) {
      annotation = Dynamic.where(id: inputs[:id], annotation_type: 'smooch_user').last
      if annotation.nil?
        raise ActiveRecord::RecordNotFound
      else
        raise "No permission to update #{annotation.class.name}" unless annotation.ability.can?(:update, annotation)
        SmoochAddSlackChannelUrlWorker.perform_in(1.second, inputs[:id], inputs[:set_fields])
        { success: true, annotation: annotation }
      end
    }
  end

  AddIntegration = GraphQL::Relay::Mutation.define do
    name 'SmoochBotAddIntegration'

    input_field :team_bot_installation_id, !types.String
    input_field :integration_type, !types.String
    input_field :params, !types.String, 'JSON string with additional parameters specific for this integration'

    return_field :team_bot_installation, TeamBotInstallationType

    resolve -> (_root, inputs, ctx) {
      _type_name, id = CheckGraphql.decode_id(inputs['team_bot_installation_id'])
      tbi = GraphqlCrudOperations.load_if_can(TeamBotInstallation, id, ctx)
      tbi.smooch_add_integration(inputs['integration_type'], JSON.parse(inputs['params']))
      { team_bot_installation: tbi }
    }
  end

  RemoveIntegration = GraphQL::Relay::Mutation.define do
    name 'SmoochBotRemoveIntegration'

    input_field :team_bot_installation_id, !types.String
    input_field :integration_type, !types.String

    return_field :team_bot_installation, TeamBotInstallationType

    resolve -> (_root, inputs, ctx) {
      _type_name, id = CheckGraphql.decode_id(inputs['team_bot_installation_id'])
      tbi = GraphqlCrudOperations.load_if_can(TeamBotInstallation, id, ctx)
      tbi.smooch_remove_integration(inputs['integration_type'])
      { team_bot_installation: tbi }
    }
  end
end
