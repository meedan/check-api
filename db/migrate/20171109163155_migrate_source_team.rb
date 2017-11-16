class MigrateSourceTeam < ActiveRecord::Migration
  def change
  	Source.where.not(team_id: nil).find_each do |s|
  	end
  end
end
