class MigrateTeamUsesrRoles < ActiveRecord::Migration[4.2]
  def change
    TeamUser.where(role: 'owner').update_all(role: 'admin')
    TeamUser.where(role: 'journalist').update_all(role: 'editor')
    TeamUser.where(role: ['contributor', 'annotator']).update_all(role: 'collaborator')
  end
end
