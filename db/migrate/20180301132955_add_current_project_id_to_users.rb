class AddCurrentProjectIdToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :current_project_id, :integer
  end
end
