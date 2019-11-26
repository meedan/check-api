require 'active_support/concern'

module TeamRules
  extend ActiveSupport::Concern

  RULES = ['contains_keyword', 'has_less_than_x_words', 'matches_regexp']

  ACTIONS = ['send_to_trash', 'move_to_project', 'ban_submitter']

  RULES_JSON_SCHEMA = File.read(File.join(Rails.root, 'public', 'rules_json_schema.json'))
  RULES_JSON_SCHEMA_VALIDATOR = JSON.parse(File.read(File.join(Rails.root, 'public', 'rules_json_schema_validator.json')))

  module Rules
    def has_less_than_x_words(pm, value)
      pm.report_type == 'claim' && pm.text.split(/\s+/).size <= value.to_i
    end

    def contains_keyword(pm, value)
      return false unless pm.report_type == 'claim'
      words = pm.text.split(/\s+/).map(&:downcase)
      keywords = value.to_s.split(',').map(&:strip).map(&:downcase)
      !(words & keywords).empty?
    end

    def matches_regexp(pm, value)
      pm.report_type == 'claim' && !pm.text.match(/#{Regexp.new(value)}/).nil?
    end
  end

  module Actions
    def send_to_trash(pm, _value)
      pm = ProjectMedia.find(pm.id)
      pm.archived = 1
      pm.save!
    end

    def move_to_project(pm, value)
      project = Project.where(team_id: self.id, id: value.to_i).last
      unless project.nil?
        pm = ProjectMedia.find(pm.id)
        pm.project_id = project.id
        pm.save!
      end
    end

    def ban_submitter(pm, _value)
      ::Bot::Smooch.ban_user(pm.smooch_message)
    end
  end

  included do
    include ::TeamRules::Rules
    include ::TeamRules::Actions
    include ErrorNotification

    validate :rules_follow_schema
    after_save :update_rules_index

    def self.rule_id(rule)
      rule.with_indifferent_access[:name].parameterize.tr('-', '_')
    end
  end

  def rules_json_schema
    RULES_JSON_SCHEMA.gsub(/%{([^}]+)}/) { I18n.t(Regexp.last_match[1]) }
  end

  def apply_rules(pm)
    all_rules_and_actions = self.get_rules || []
    all_rules_and_actions.map(&:with_indifferent_access).each do |rules_and_actions|
      next if !rules_and_actions[:project_ids].blank? && !rules_and_actions[:project_ids].split(',').map(&:to_i).include?(pm.project_id)
      matches = 0
      rules_and_actions[:rules].each do |rule|
        matches += 1 if ::TeamRules::RULES.include?(rule[:rule_definition]) && self.send(rule[:rule_definition], pm, rule[:rule_value])
      end
      matches_rule = matches == rules_and_actions[:rules].size
      yield(rules_and_actions) if matches_rule
    end
  end

  def apply_rules_and_actions(pm)
    matched_rules_ids = []
    self.apply_rules(pm) do |rules_and_actions|
      rules_and_actions[:actions].each do |action|
        if ::TeamRules::ACTIONS.include?(action[:action_definition])
          pm.skip_check_ability = true
          self.send(action[:action_definition], pm, action[:action_value])
          pm.skip_check_ability = false
        end
        matched_rules_ids << Team.rule_id(rules_and_actions)
      end
    end
    pm.update_elasticsearch_doc(['rules'], { 'rules' => matched_rules_ids }, pm)
  end

  def rules_changed?
    rules_were = self.settings_was.to_h.with_indifferent_access[:rules]
    rules_are = self.get_rules
    rules_were != rules_are && (!rules_were.blank? || !rules_are.blank?)
  end

  def rules_search_fields_json_schema
    return nil if self.get_rules.blank?
    properties = {
      rules: { type: 'object', properties: {} }
    }
    self.get_rules.each do |rule|
      id = Team.rule_id(rule)
      properties[:rules][:properties][id] = { type: 'string', title: rule.with_indifferent_access[:name] }
    end
    { type: 'object', properties: properties }
  end

  private

  def rules_follow_schema
    errors.add(:settings, 'must follow the schema') if !self.get_rules.blank? && !JSON::Validator.validate(RULES_JSON_SCHEMA_VALIDATOR, self.get_rules)
  end

  def update_rules_index
    if self.rules_changed?
      Rails.cache.write("cancel_rules_indexing_for_team_#{self.id}") if Rails.cache.read("rules_indexing_in_progress_for_team_#{self.id}")
      RulesIndexWorker.perform_in(5.seconds, self.id)
    end
  end
end
