class RemoveTeamwideFromTagTexts < ActiveRecord::Migration
  def change
    remove_column :tag_texts, :teamwide
  end
end
