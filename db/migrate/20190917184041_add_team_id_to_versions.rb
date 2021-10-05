class AddTeamIdToVersions < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :team_id, :integer
    add_index :versions, :team_id
    Rails.cache.write('check:migrate:versions_team_id:last_id', PaperTrail::Version.last&.id || 0)
  end
end
