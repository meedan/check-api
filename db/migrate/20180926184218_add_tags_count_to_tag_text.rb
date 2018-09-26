class AddTagsCountToTagText < ActiveRecord::Migration
  def change
    add_column :tag_texts, :tags_count, :integer, default: 0
  end
end
