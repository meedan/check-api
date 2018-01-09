class RemoveTeamNameSloganAndAvatarFromSources < ActiveRecord::Migration
  def change
  	remove_column :sources, :team_id
  	remove_column :sources, :name
  	remove_column :sources, :slogan
  	remove_column :sources, :avatar
  	remove_column :sources, :archived
  	remove_column :sources, :lock_version
  end
end
