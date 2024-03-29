module TranscriptionMutations
  class TranscribeAudio < Mutations::BaseMutation
    argument :id, GraphQL::Types::ID, required: true

    field :project_media, ProjectMediaType, null: true, camelize: false
    field :annotation, DynamicType, null: true

    def resolve(id:)
      project_media = GraphqlCrudOperations.object_from_id_if_can(
        id,
        context[:ability]
      )

      annotation = Bot::Alegre.transcribe_audio(project_media)

      output = {
        project_media: project_media,
        annotation: annotation.reload
      }

      output
    end
  end
end
