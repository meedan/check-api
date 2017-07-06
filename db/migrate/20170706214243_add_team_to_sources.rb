class AddTeamToSources < ActiveRecord::Migration
  def change
    add_reference :sources, :team, index: true, foreign_key: true
    Source.find_each do |s|
      u = s.user
      t = u.teams.first unless u.nil?
      s.update_columns(team_id: t.id) unless t.nil?
    end
  end
end
