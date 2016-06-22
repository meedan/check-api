UserType = GraphQL::ObjectType.define do
  name 'User'
  description 'User type'

  interfaces [NodeIdentification.interface]

  field :id, field: GraphQL::Relay::GlobalIdField.new('User')
  field :updated_at, types.String
  field :created_at, types.String
  field :last_sign_in_ip, types.String
  field :current_sign_in_ip, types.String
  field :last_sign_in_at, types.String
  field :current_sign_in_at, types.String
  field :sign_in_count, types.Int
  field :remember_created_at, types.String
  field :reset_password_sent_at, types.String
  field :reset_password_token, types.String
  field :encrypted_password, types.String
  field :email, types.String
  field :token, types.String
  field :provider, types.String
  field :uuid, types.String
  field :profile_image, types.String
  field :login, types.String
  field :name, types.String
  # End of fields
end
