class AnnotatorType < BaseObject
  description "Information about an annotator"

  implements NodeIdentification.interface

  global_id_field :id

  field :name, GraphQL::Types::String, null: true
  field :profile_image, GraphQL::Types::String, null: true

  field :user, UserType, null: true

  def user
    User.where(id: object.id).last if object.is_a?(User)
  end
end
