class AboutType < DefaultObject
  description "Information about the application"

  implements GraphQL::Types::Relay::Node

  field :name, GraphQL::Types::String, "Application name", null: true
  field :version, GraphQL::Types::String, "Application version", null: true
  field :upload_max_dimensions, GraphQL::Types::String, "Maximum image dimensions", null: true
  field :upload_min_dimensions, GraphQL::Types::String, "Minimum image dimensions", null: true
  field :languages_supported, GraphQL::Types::String, "Supported languages", null: true
  field :terms_last_updated_at, GraphQL::Types::Int, "Terms last update date", null: true

  field :upload_extensions, [GraphQL::Types::String, null: true], "Allowed upload types", null: true
  field :file_extensions, [GraphQL::Types::String, null: true], "Allowed file types", null: true
  field :video_extensions, [GraphQL::Types::String, null: true], "Allowed video types", null: true
  field :audio_extensions, [GraphQL::Types::String, null: true], "Allowed audio types", null: true

  field :upload_max_size, GraphQL::Types::String, "Maximum upload size, in human-readable format", null: true
  field :file_max_size, GraphQL::Types::String, "Maximum file upload size, in human-readable format", null: true
  field :video_max_size, GraphQL::Types::String, "Maximum video upload size, in human-readable format", null: true
  field :audio_max_size, GraphQL::Types::String, "Maximum audio upload size, in human-readable format", null: true

  field :upload_max_size_in_bytes, GraphQL::Types::Int, "Maximum upload size, in bytes", null: true
  field :file_max_size_in_bytes, GraphQL::Types::Int, "Maximum file upload size, in bytes", null: true
  field :video_max_size_in_bytes, GraphQL::Types::Int, "Maximum video upload size, in bytes", null: true
  field :audio_max_size_in_bytes, GraphQL::Types::Int, "Maximum audio upload size, in bytes", null: true

  field :channels, JsonString, "List check channels", null: true
  field :countries, JsonString, "List of workspace countries", null: true
end
