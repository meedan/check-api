# TODO Can we just use UserType instead of this?
AnnotatorType = GraphQL::ObjectType.define do
  name 'Annotator'
  description 'The author of an annotation.'
  interfaces [NodeIdentification.interface]
  global_id_field :id

  field :name, types.String, 'Name'
  field :profile_image, types.String, 'Picture' # TODO Rename to 'picture'

  field :user, UserType do
    description 'Annotator'

    resolve -> (annotator, _args, _ctx) {
      User.where(id: annotator.id).last if annotator.is_a?(User)
    }
  end
end
