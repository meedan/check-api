class MigrateCommentsFromPgToEs < ActiveRecord::Migration
  def change
    Annotation.where(annotation_type: 'comment', annotated_type: 'Media').where.not(context_id: nil).each do |c|
      c.add_update_media_search_child('comment_search', %w(text))
    end
  end
end
