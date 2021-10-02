module TranscriptionMutations
  TranscribeAudio = GraphQL::Relay::Mutation.define do
    name 'TranscribeAudio'

    input_field :id, !types.ID

    return_field :project_media, ProjectMediaType

    resolve -> (_root, inputs, ctx) {
      pm = GraphqlCrudOperations.object_from_id_if_can(inputs['id'], ctx['ability'])
      Bot::Alegre.transcribe_audio(pm)
      { project_media: pm }
    }
  end
end
