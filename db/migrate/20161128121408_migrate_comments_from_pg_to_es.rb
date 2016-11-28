class MigrateCommentsFromPgToEs < ActiveRecord::Migration
  def change
    Annotation.where(annotation_type: 'comment').each do |c|
      c.add_update_media_search_child('comment_search', %w(text))
    end
  end
end
