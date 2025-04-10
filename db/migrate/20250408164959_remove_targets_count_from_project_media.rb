class RemoveTargetsCountFromProjectMedia < ActiveRecord::Migration[6.1]
  def change
    remove_column :project_medias, :targets_count
  end
end
