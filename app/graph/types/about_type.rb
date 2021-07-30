AboutType = GraphQL::ObjectType.define do
  name 'About'
  description 'Information about the application'
  interfaces [NodeIdentification.interface]
  global_id_field :id

  field :name, types.String, 'Application name'
  field :version, types.String, 'Application version'
  field :upload_max_dimensions, types.String, 'Maximum image dimensions'
  field :upload_min_dimensions, types.String, 'Minimum image dimensions'
  field :languages_supported, types.String, 'Supported languages'
  field :terms_last_updated_at, types.Int, 'Terms last update date'

  field :upload_extensions, types[types.String], 'Allowed upload types'
  field :file_extensions, types[types.String], 'Allowed file types'
  field :video_extensions, types[types.String], 'Allowed video types'
  field :audio_extensions, types[types.String], 'Allowed audio types'

  field :upload_max_size, types.String, 'Maximum upload size, in human-readable format'
  field :file_max_size, types.String, 'Maximum file upload size, in human-readable format'
  field :video_max_size, types.String, 'Maximum video upload size, in human-readable format'
  field :audio_max_size, types.String, 'Maximum audio upload size, in human-readable format'

  field :upload_max_size_in_bytes, types.Int, 'Maximum upload size, in bytes'
  field :file_max_size_in_bytes, types.Int, 'Maximum file upload size, in bytes'
  field :video_max_size_in_bytes, types.Int, 'Maximum video upload size, in bytes'
  field :audio_max_size_in_bytes, types.Int, 'Maximum audio upload size, in bytes'

  field :channels, JsonStringType, 'List check channels'
end
