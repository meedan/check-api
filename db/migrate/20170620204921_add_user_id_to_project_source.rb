class AddUserIdToProjectSource < ActiveRecord::Migration
  def change
    add_reference :project_sources, :user, index: true, foreign_key: true
    ProjectSource.find_each do |ps|
      ps.user_id = ps.source.user_id
      ps.save!
    end
  end
end
