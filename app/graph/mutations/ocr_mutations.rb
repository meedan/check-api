module OcrMutations
  class ExtractText < Mutations::BaseMutation
    argument :id, GraphQL::Types::ID, required: true

    field :project_media, ProjectMediaType, null: true, camelize: false

    def resolve(id:)
      pm = GraphqlCrudOperations.object_from_id_if_can(
        id,
        context[:ability]
      )
      Bot::Alegre.get_extracted_text(pm)
      { project_media: pm }
    end
  end
end
