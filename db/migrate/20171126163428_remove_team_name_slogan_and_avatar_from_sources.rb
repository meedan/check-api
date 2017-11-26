class RemoveTeamNameSloganAndAvatarFromSources < ActiveRecord::Migration
  def change
  	remove_column :sources, :team_id
  	remove_column :sources, :name
  	remove_column :sources, :slogan
  	remove_column :sources, :avatar
  end
end
