class AddInvitationEmailToTeamUser < ActiveRecord::Migration
  def change
    add_column :team_users, :invitation_email, :string
    TeamUser.where(status: 'invited').find_each do |tu|
    	tu.update_column(:invitation_email, tu.user.email)
    end
  end
end
