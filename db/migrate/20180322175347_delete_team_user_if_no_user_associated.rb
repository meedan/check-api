class DeleteTeamUserIfNoUserAssociated < ActiveRecord::Migration
  def change
  	TeamUser.find_each {|tu| tu.destroy if tu.user.nil?}
  end
end
