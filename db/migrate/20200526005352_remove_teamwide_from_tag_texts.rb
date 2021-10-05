class RemoveTeamwideFromTagTexts < ActiveRecord::Migration[4.2]
  def change
    remove_column :tag_texts, :teamwide
  end
end
