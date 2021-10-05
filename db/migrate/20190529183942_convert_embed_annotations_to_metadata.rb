class ConvertEmbedAnnotationsToMetadata < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:convert_embed_annotations_to_metadata:progress', nil)
  end
end
