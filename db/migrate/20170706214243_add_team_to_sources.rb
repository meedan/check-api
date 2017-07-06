class AddTeamToSources < ActiveRecord::Migration
  def change
    add_reference :sources, :team, index: true, foreign_key: true
    Source.find_each do |s|
      t = s.user.teams.first
      s.team = t
      s.save!
    end
  end
end
