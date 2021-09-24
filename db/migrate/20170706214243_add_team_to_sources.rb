class AddTeamToSources < ActiveRecord::Migration[4.2]
  def change
    add_column :sources, :team_id, :integer
    add_index :sources, :team_id
    Source.find_each do |s|
      u = s.user
      t = u.teams.first unless u.nil?
      s.update_columns(team_id: t.id) unless t.nil?
    end
  end
end
