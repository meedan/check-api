class ConvertRulesToNewSchema < ActiveRecord::Migration[4.2]
  def change
    Team.all.find_each do |team|
      rules = team.get_rules
      unless rules.blank?
        puts "Updating rules for team #{team.name}..."
        new_rules = []
        names = rules.collect{ |r| r['name'] }
        rules.each do |rule|
          conditions = []
          rule['rules'].each do |condition|
            if condition['rule_definition'] == 'flagged_as'
              condition['rule_value'] = JSON.parse(condition['rule_value'])
            end
            conditions << condition.clone
          end
          name = rule['name']
          if name.blank? || names.select{ |n| n == name }.size > 1
            name = "Rule #{rand(100000)}"
          end
          new_rule = {
            name: name,
            project_ids: rule['project_ids'],
            actions: rule['actions'].clone,
            created_at: Time.now.to_i,
            rules: {
              operator: 'and',
              groups: [
                {
                  operator: 'and',
                  conditions: conditions
                }
              ]
            }
          }
          new_rules << new_rule
        end
        team.rules = new_rules.to_json
        team.save!
      end
    end
  end
end
