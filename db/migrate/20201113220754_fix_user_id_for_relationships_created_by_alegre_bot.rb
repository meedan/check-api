class FixUserIdForRelationshipsCreatedByAlegreBot < ActiveRecord::Migration
  def change
    bot = BotUser.alegre_user
    unless bot.nil?
      Relationship.where(user_id: nil).update_all(user_id: bot.id)
    end
  end
end
