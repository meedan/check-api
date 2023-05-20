module Types
  class TeamTaskType < DefaultObject
    description "Team task type"

    implements GraphQL::Types::Relay::NodeField

    field :dbid, Integer, null: true
    field :label, String, null: true
    field :description, String, null: true
    field :options, Types::JsonString, null: true
    field :required, Boolean, null: true
    field :team_id, Integer, null: true
    field :team, TeamType, null: true
    field :json_schema, String, null: true
    field :order, Integer, null: true
    field :fieldset, String, null: true
    field :associated_type, String, null: true
    field :show_in_browser_extension, Boolean, null: true
    field :conditional_info, String, null: true
    field :tasks_count, Integer, null: true
    field :tasks_with_answers_count, Integer, null: true

    field :type, String, null: true

    def type
      object.task_type
    end
  end
end
