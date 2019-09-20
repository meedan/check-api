class AddUserIdToProjectSource < ActiveRecord::Migration
  def change
    add_column :project_sources, :user_id, :integer
    add_index :project_sources, :user_id
    ProjectSource.find_each do |ps|
      ps.user_id = ps.source.user_id
      ps.save!
    end
  end
end
