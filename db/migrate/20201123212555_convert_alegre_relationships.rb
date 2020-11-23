class ConvertAlegreRelationships < ActiveRecord::Migration
  def change
    confirmables = []
    suggestables = []
    Relationship.where(user_id: BotUser.alegre_user.id, relationship_type: Relationship.default_type.to_yaml).find_each do |relationship|
      if Bot::Smooch.team_has_smooch_bot_installed(relationship.target)
        confirmables << relationship.id
      else
        suggestables << relationship.id
      end
    end
    Relationship.where(id: confirmables).update_all(relationship_type: Relationship.confirmed_type.to_yaml)
    Relationship.where(id: suggestables).update_all(relationship_type: Relationship.suggested_type.to_yaml)
  end
end
