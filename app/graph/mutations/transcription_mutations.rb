module TranscriptionMutations
  TranscribeAudio = GraphQL::Relay::Mutation.define do
    name 'TranscribeAudio'

    return_field :project_media, ProjectMediaType
    return_field :annotation, DynamicType

    input_field :id, !types.ID

    resolve -> (_r, input, context) {
      project_media = GraphqlCrudOperations.object_from_id_if_can(input['id'], context['ability'])

      annotation = Bot::Alegre.transcribe_audio(project_media)

      output = {
        project_media: project_media,
        annotation: annotation.reload
      }

      return output
    }
  end
end
