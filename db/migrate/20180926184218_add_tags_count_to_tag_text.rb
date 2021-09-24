class AddTagsCountToTagText < ActiveRecord::Migration[4.2]
  def change
    TagText.reset_column_information
    add_column(:tag_texts, :tags_count, :integer, default: 0) unless TagText.column_names.include?('tags_count')
  end
end
