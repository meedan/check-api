class AddSubdomainToTeam < ActiveRecord::Migration
  def change
    add_column :teams, :subdomain, :string
    add_index :teams, :subdomain
    # Fix existing records
    Team.all.each do |team|
      team.subdomain = Team.subdomain_from_name(team.name)
      team.save
    end
  end
end
