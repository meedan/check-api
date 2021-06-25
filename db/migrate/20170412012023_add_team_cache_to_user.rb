class AddTeamCacheToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :cached_teams, :text
    User.reset_column_information
    User.all.each do |user|
      user.cached_teams = user.teams.map(&:id)
      user.save(validate: false)
      puts "Saved user #{user.id}"
    end
  end
end
