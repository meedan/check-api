class AddStatusToTeamUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :team_users, :status, :string, default: "member", index: true
    # Fix existing records
    TeamUser.all.each do |tu|
      tu.status = "member"
      tu.save
    end
  end
end
