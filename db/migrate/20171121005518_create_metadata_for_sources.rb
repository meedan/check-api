class CreateMetadataForSources < ActiveRecord::Migration[4.2]
  def change
    Source.find_each do |source|
      if source.get_annotations(['metadata']).empty?
        d = Dynamic.new
        d.annotation_type = 'metadata'
        d.annotator = source.user
        d.annotated = source
        d.set_fields = { metadata_value: {}.to_json }.to_json
        d.skip_check_ability = true
        d.skip_notifications = true
        d.save!
      end
    end
  end
end
