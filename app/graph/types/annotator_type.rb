class AnnotatorType < BaseObject
  description "Information about an annotator"

  implements NodeIdentification.interface

  field :name, String, null: true
  field :profile_image, String, null: true

  field :user, UserType, null: true

  def user
    User.where(id: object.id).last if object.is_a?(User)
  end
end
