AboutType = GraphQL::ObjectType.define do
  name 'About'
  description 'Information about the application'
  interfaces [NodeIdentification.interface]
  global_id_field :id
  field :name, types.String, 'Application name'
  field :version, types.String, 'Application version'
  field :upload_max_size, types.String, 'Maximum upload size'
  field :upload_extensions, types.String, 'Allowed upload types'
  field :video_max_size, types.String, 'Maximum video upload size'
  field :video_extensions, types.String, 'Allowed video types'
  field :upload_max_dimensions, types.String, 'Maximum image dimensions'
  field :upload_min_dimensions, types.String, 'Minimum image dimensions'
  field :languages_supported, types.String, 'Supported languages'
  field :terms_last_updated_at, types.Int, 'Terms last update date'
end
