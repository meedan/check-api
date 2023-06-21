module SmoochBotMutations
  class AddSlackChannelUrl < Mutation::Base
    graphql_name "SmoochBotAddSlackChannelUrl"

    argument :id, String, required: true
    argument :set_fields, String, required: true

    field :success, Boolean, null: true
    field :annotation, AnnotationType, null: true

    def resolve(**inputs)
      annotation =
                Dynamic.where(
                  id: inputs[:id],
                  annotation_type: "smooch_user"
                ).last
              if annotation.nil?
                raise ActiveRecord::RecordNotFound
              else
                unless annotation.ability.can?(:update, annotation)
                  raise "No permission to update #{annotation.class.name}"
                end
                SmoochAddSlackChannelUrlWorker.perform_in(
                  1.second,
                  inputs[:id],
                  inputs[:set_fields]
                )
                { success: true, annotation: annotation }
              end
    end
  end

  class AddIntegration < Mutation::Base
    graphql_name "SmoochBotAddIntegration"

    argument :team_bot_installation_id, String, required: true
    argument :integration_type, String, required: true
    argument :params, String, "JSON string with additional parameters specific for this integration", required: true

    field :team_bot_installation, TeamBotInstallationType, null: true

    def resolve(**inputs)
      _type_name, id =
                CheckGraphql.decode_id(inputs[:team_bot_installation_id])
              tbi =
                GraphqlCrudOperations.load_if_can(
                  TeamBotInstallation,
                  id,
                  context
                )
              tbi.smooch_add_integration(
                inputs[:integration_type],
                JSON.parse(inputs[:params])
              )
              { team_bot_installation: tbi }
    end
  end

  class RemoveIntegration < Mutation::Base
    graphql_name "SmoochBotRemoveIntegration"

    argument :team_bot_installation_id, String, required: true
    argument :integration_type, String, required: true

    field :team_bot_installation, TeamBotInstallationType, null: true

    def resolve(**inputs)
      _type_name, id =
                CheckGraphql.decode_id(inputs[:team_bot_installation_id])
              tbi =
                GraphqlCrudOperations.load_if_can(
                  TeamBotInstallation,
                  id,
                  context
                )
              tbi.smooch_remove_integration(inputs[:integration_type])
              { team_bot_installation: tbi }
    end
  end
end
