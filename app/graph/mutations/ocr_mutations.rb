module OcrMutations
  ExtractText = GraphQL::Relay::Mutation.define do
    name 'ExtractText'

    input_field :id, !types.ID

    return_field :project_media, ProjectMediaType

    resolve -> (_root, inputs, ctx) {
      pm = GraphqlCrudOperations.object_from_id_if_can(inputs['id'], ctx['ability'])
      Bot::Alegre.get_extracted_text(pm)
      { project_media: pm }
    }
  end
end
