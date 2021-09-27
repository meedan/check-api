class DeleteTeamUserIfNoUserAssociated < ActiveRecord::Migration[4.2]
  def change
  	TeamUser.find_each {|tu| tu.destroy if tu.user.nil?}
  end
end
