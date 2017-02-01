AboutType = GraphQL::ObjectType.define do
  name 'About'
  description 'Information about the application'
  interfaces [NodeIdentification.interface]      
  global_id_field :id
  field :name, types.String, 'Application name'
  field :version, types.String, 'Application version'
  field :tos, types.String, 'Terms of Service'
  field :privacy_policy, types.String, 'Privacy Policy'
  field :max_upload_size, types.String, 'Maximum upload size'
end
