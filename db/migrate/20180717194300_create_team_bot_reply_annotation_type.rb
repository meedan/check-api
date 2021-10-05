class CreateTeamBotReplyAnnotationType < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData
  
  def change
    # Formatted Data is expected to be a hash of strings: title, description and image_url
    create_annotation_type_and_fields('Team Bot Response', { 'Raw Data' => ['JSON', true], 'Formatted Data' => ['Bot Response Format', false] })
  end
end
