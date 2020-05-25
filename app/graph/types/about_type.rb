AboutType = GraphQL::ObjectType.define do
  name 'About'
  description 'Information about the application.'
  interfaces [NodeIdentification.interface]
  global_id_field :id
  field :name, types.String, 'Application name.'
  field :version, types.String, 'Application version.'
  field :languages_supported, types.String, 'Languages supported by the application.'
  field :terms_last_updated_at, types.Int, 'Last update date of the terms of use (Unix timestamp).'
  field :image_max_size, types.String, 'Maximum image upload size.'
  field :image_extensions, types.String, 'Allowed image types.'
  field :image_max_dimensions, types.String, 'Maximum image dimensions.'
  field :image_min_dimensions, types.String, 'Minimum image dimensions.'
  field :video_max_size, types.String, 'Maximum video upload size.'
  field :video_extensions, types.String, 'Allowed video types.'
end
