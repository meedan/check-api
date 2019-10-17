module SmoochRules
  extend ActiveSupport::Concern

  RULES = ['contains_keyword', 'has_less_than_x_words', 'matches_regexp']
  ACTIONS = ['send_to_trash', 'move_to_project']

  module Rules
    def has_less_than_x_words(_pm, message, value)
      message['text'].split(/\s+/).size <= value.to_i
    end

    def contains_keyword(_pm, message, value)
      words = message['text'].split(/\s+/)
      keywords = value.to_s.split(',')
      !(words & keywords).empty?
    end

    def matches_regexp(_pm, message, value)
      !message['text'].match(/#{Regexp.new(value)}/).nil?
    end
  end

  module Actions
    def send_to_trash(pm, _message, _value)
      pm.archived = 1
      pm.save!
    end

    def move_to_project(pm, _message, value)
      if value
        pm.project_id = value.to_i
        pm.save!
      end
    end
  end
  
  module ClassMethods
    include ::SmoochRules::Rules
    include ::SmoochRules::Actions

    def apply_rules_and_actions(pm, message)
      config = self.config || {}
      all_rules_and_actions = config[:smooch_rules_and_actions] || []
      all_rules_and_actions.each do |rules_and_actions|
        matches = 0
        rules_and_actions[:smooch_rules].each do |rule|
          if ::SmoochRules::RULES.include?(rule[:smooch_rule_definition]) && self.send(rule[:smooch_rule_definition], pm, message, rule[:smooch_rule_value])
            matches += 1
          end
        end
        if matches == rules_and_actions[:smooch_rules].size
          rules_and_actions[:smooch_actions].each do |action|
            if ::SmoochRules::ACTIONS.include?(action[:smooch_action_definition])
              self.send(action[:smooch_action_definition], pm, message, action[:smooch_action_value])
            end
          end
        end
      end
    end
  end
end
