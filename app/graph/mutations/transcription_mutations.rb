module TranscriptionMutations
  class TranscribeAudio < BaseMutation
    argument :id, ID, required: true

    field :project_media, ProjectMediaType, null: true, camelize: false
    field :annotation, DynamicType, null: true

    def resolve(**input)
      project_media = GraphqlCrudOperations.object_from_id_if_can(
        input[:id],
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
