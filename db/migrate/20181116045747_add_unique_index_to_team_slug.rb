class AddUniqueIndexToTeamSlug < ActiveRecord::Migration
  def change
    add_index :teams, :slug, unique: true, name: 'unique_team_slugs'
  end
end
