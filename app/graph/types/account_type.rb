AccountType = GraphqlCrudOperations.define_default_type do
  name 'Account'
  description 'Account type'

  implements NodeIdentification.interface

  field :data, String, null: true
  field :dbid, Integer, null: true
  field :url, String, null: false
  field :provider, String, null: true
  field :uid, String, null: true
  field :user_id, Integer, null: true
  field :permissions, String, null: true
  field :image, String, null: true
  field :user, UserType, null: true

  def user
    object.user
  end

  field :medias, MediaType.connection_type, null: true, connection: true

  def medias
    object.medias
  end

  field :metadata, JsonStringType, null: true

  def metadata
    object.metadata
  end
end
