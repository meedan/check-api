class TeamTaskType < DefaultObject
  description "Team task type"

  implements NodeIdentification.interface

  field :dbid, GraphQL::Types::Int, null: true
  field :label, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: true
  field :options, JsonString, null: true
  field :required, GraphQL::Types::Boolean, null: true
  field :team_id, GraphQL::Types::Int, null: true
  field :team, TeamType, null: true
  field :json_schema, GraphQL::Types::String, null: true
  field :order, GraphQL::Types::Int, null: true
  field :fieldset, GraphQL::Types::String, null: true
  field :associated_type, GraphQL::Types::String, null: true
  field :show_in_browser_extension, GraphQL::Types::Boolean, null: true
  field :conditional_info, GraphQL::Types::String, null: true
  field :tasks_count, GraphQL::Types::Int, null: true
  field :tasks_with_answers_count, GraphQL::Types::Int, null: true

  field :type, GraphQL::Types::String, null: true

  def type
    object.task_type
  end
end
