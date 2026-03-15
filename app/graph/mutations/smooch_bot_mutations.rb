module SmoochBotMutations
  class AddIntegration < Mutations::BaseMutation
    graphql_name "SmoochBotAddIntegration"

    argument :team_bot_installation_id, GraphQL::Types::String, required: true, camelize: false
    argument :integration_type, GraphQL::Types::String, required: true, camelize: false
    argument :params, GraphQL::Types::String, "JSON string with additional parameters specific for this integration", required: true

    field :team_bot_installation, TeamBotInstallationType, null: true, camelize: false

    def resolve(team_bot_installation_id:, integration_type:, params:)
      _type_name, id = CheckGraphql.decode_id(team_bot_installation_id)
      tbi = GraphqlCrudOperations.load_if_can(
        TeamBotInstallation,
        id,
        context
      )
      tbi.smooch_add_integration(integration_type,JSON.parse(params))
      { team_bot_installation: tbi }
    end
  end

  class RemoveIntegration < Mutations::BaseMutation
    graphql_name "SmoochBotRemoveIntegration"

    argument :team_bot_installation_id, GraphQL::Types::String, required: true, camelize: false
    argument :integration_type, GraphQL::Types::String, required: true, camelize: false

    field :team_bot_installation, TeamBotInstallationType, null: true, camelize: false

    def resolve(team_bot_installation_id:, integration_type:)
      _type_name, id = CheckGraphql.decode_id(team_bot_installation_id)
      tbi = GraphqlCrudOperations.load_if_can(
        TeamBotInstallation,
        id,
        context
      )
      tbi.smooch_remove_integration(integration_type)
      { team_bot_installation: tbi }
    end
  end
end
