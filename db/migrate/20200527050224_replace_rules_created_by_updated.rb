class ReplaceRulesCreatedByUpdated < ActiveRecord::Migration
  def change
    Team.all.find_each do |team|
      rules = team.get_rules
      unless rules.blank?
        puts "Replacing created_at by updated_at on rules for team #{team.name}..."
        new_rules = []
        rules.each do |rule|
          new_rule = rule.clone.with_indifferent_access.except(:created_at)
          new_rule[:updated_at] = Time.now.to_i
          new_rules << new_rule
        end
        team.rules = new_rules.to_json
        team.save!
      end
    end
  end
end
