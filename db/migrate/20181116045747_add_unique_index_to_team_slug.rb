class AddUniqueIndexToTeamSlug < ActiveRecord::Migration[4.2]
  def change
    add_index :teams, :slug, unique: true, name: 'unique_team_slugs'
  end
end
