AnnotatorType = GraphQL::ObjectType.define do
  name 'Annotator'
  description 'Information about an annotator'
  interfaces [NodeIdentification.interface]
  global_id_field :id

  field :name, types.String
  field :profile_image, types.String

  field :user, UserType do
    resolve -> (annotator, _args, _ctx) {
      User.where(id: annotator.id).last if annotator.is_a?(User)
    }
  end
end
