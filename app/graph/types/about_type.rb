class AboutType < DefaultObject
  description "Information about the application"

  implements NodeIdentification.interface

  field :name, String, "Application name", null: true
  field :version, String, "Application version", null: true
  field :upload_max_dimensions, String, "Maximum image dimensions", null: true
  field :upload_min_dimensions, String, "Minimum image dimensions", null: true
  field :languages_supported, String, "Supported languages", null: true
  field :terms_last_updated_at, Integer, "Terms last update date", null: true

  field :upload_extensions, [String, null: true], "Allowed upload types", null: true
  field :file_extensions, [String, null: true], "Allowed file types", null: true
  field :video_extensions, [String, null: true], "Allowed video types", null: true
  field :audio_extensions, [String, null: true], "Allowed audio types", null: true

  field :upload_max_size, String, "Maximum upload size, in human-readable format", null: true
  field :file_max_size, String, "Maximum file upload size, in human-readable format", null: true
  field :video_max_size, String, "Maximum video upload size, in human-readable format", null: true
  field :audio_max_size, String, "Maximum audio upload size, in human-readable format", null: true

  field :upload_max_size_in_bytes, Integer, "Maximum upload size, in bytes", null: true
  field :file_max_size_in_bytes, Integer, "Maximum file upload size, in bytes", null: true
  field :video_max_size_in_bytes, Integer, "Maximum video upload size, in bytes", null: true
  field :audio_max_size_in_bytes, Integer, "Maximum audio upload size, in bytes", null: true

  field :channels, JsonString, "List check channels", null: true
  field :countries, JsonString, "List of workspace countries", null: true
end
