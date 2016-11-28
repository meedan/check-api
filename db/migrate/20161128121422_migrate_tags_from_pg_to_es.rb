class MigrateTagsFromPgToEs < ActiveRecord::Migration
  def change
    Annotation.where(annotation_type: 'tag').each do |t|
      t.add_update_media_search_child('tag_search', %w(tag full_tag))
    end
  end
end
