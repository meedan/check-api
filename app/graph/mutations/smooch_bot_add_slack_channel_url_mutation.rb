SmoochBotAddSlackChannelUrlMutation = GraphQL::Relay::Mutation.define do
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
      # calling sidekig job
      SmoochAddSlackChannelUrlWorker.perform_in(1.second, inputs[:id], inputs[:set_fields])
      { success: true, annotation: annotation }
    end
  }
end
