require 'active_support/concern'

module TeamRules
  extend ActiveSupport::Concern

  RULES = ['contains_keyword', 'has_less_than_x_words', 'matches_regexp', 'type_is', 'tagged_as', 'status_is']

  ACTIONS = ['send_to_trash', 'move_to_project', 'ban_submitter', 'copy_to_project']

  RULES_JSON_SCHEMA = File.read(File.join(Rails.root, 'public', 'rules_json_schema.json'))
  RULES_JSON_SCHEMA_VALIDATOR = JSON.parse(File.read(File.join(Rails.root, 'public', 'rules_json_schema_validator.json')))

  module Rules
    def has_less_than_x_words(pm, obj, value)
      obj.nil? && pm.report_type == 'claim' && pm.text.split(/\s+/).size <= value.to_i
    end

    def contains_keyword(pm, obj, value)
      return false unless obj.nil?
      return false unless pm.report_type == 'claim'
      words = pm.text.scan(/\w+/).to_a.map(&:downcase)
      keywords = value.to_s.split(',').map(&:strip).map(&:downcase)
      !(words & keywords).empty?
    end

    def matches_regexp(pm, obj, value)
      obj.nil? && pm.report_type == 'claim' && !pm.text.match(/#{Regexp.new(value)}/).nil?
    end

    def type_is(pm, obj, value)
      obj.nil? && pm.report_type == value
    end

    def tagged_as(_pm, tag, value)
      tag.is_a?(Tag) && tag.tag_text == value
    end

    def status_is(_pm, status, value)
      status.is_a?(DynamicAnnotation::Field) && status.field_name == 'verification_status_status' && status.value == value
    end
  end

  module Actions
    def send_to_trash(pm, _value)
      pm = ProjectMedia.find(pm.id)
      pm.archived = 1
      pm.save!
    end

    def ban_submitter(pm, _value)
      ::Bot::Smooch.ban_user(pm.smooch_message)
    end

    def move_to_project(pm, value)
      self.copy_or_move_to_project(pm, value, 'project_id')
    end

    def copy_to_project(pm, value)
      self.copy_or_move_to_project(pm, value, 'copy_to_project_id')
    end

    def copy_or_move_to_project(pm, value, attr)
      project = Project.where(team_id: self.id, id: value.to_i).last
      unless project.nil?
        pm = ProjectMedia.find(pm.id)
        pm.send("#{attr}=", project.id)
        pm.save!
      end
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
    json_schema = RULES_JSON_SCHEMA.gsub(/%{([^}]+)}/) { I18n.t(Regexp.last_match[1]) }
    schema = JSON.parse(json_schema)
    projects = self.projects.order('title ASC').collect{ |p| { key: p.id, value: p.title } }
    types = ['Claim', 'Link', 'UploadedImage', 'UploadedVideo'].collect{ |t| { key: t.downcase, value: I18n.t("team_rule_type_is_#{t.downcase}") } }
    tags = self.tag_texts.collect{ |t| { key: t.text, value: t.text } }
    pm = ProjectMedia.new(project: Project.new(team_id: self.id))
    statuses = ::Workflow::Workflow.options(pm, pm.default_project_media_status_type)[:statuses]
    statuses = statuses.collect{ |st| { key: st.with_indifferent_access['id'], value: st.with_indifferent_access['label'] } }

    schema['properties']['rules']['items']['properties']['project_ids']['enum'] = [{ key: '0', value: I18n.t(:team_rule_all_items) }].concat(projects);

    {
      'actions' => {
        'action_value_move_to_project' => { title: I18n.t(:team_rule_destination), type: 'string', enum: projects },
        'action_value_copy_to_project' => { title: I18n.t(:team_rule_destination), type: 'string', enum: projects }
      },
      'rules' => {
        'rule_value_type_is' => { title: I18n.t(:team_rule_select_type), type: 'string', enum: types },
        'rule_value_tagged_as' => { title: I18n.t(:team_rule_select_tag), type: 'string', enum: tags },
        'rule_value_status_is' => { title: I18n.t(:team_rule_select_status), type: 'string', enum: statuses }
      }
    }.each do |section, fields|
      fields.each do |property, value|
        schema['properties']['rules']['items']['properties'][section]['items']['properties'][property] = value
      end
    end

    schema.to_json
  end

  def apply_rules(pm, obj = nil)
    all_rules_and_actions = self.get_rules || []
    all_rules_and_actions.map(&:with_indifferent_access).each do |rules_and_actions|
      next if !rules_and_actions[:project_ids].blank? && !rules_and_actions[:project_ids].split(',').map(&:to_i).include?(pm.project_id)
      matches = 0
      rules_and_actions[:rules].each do |rule|
        matches += 1 if ::TeamRules::RULES.include?(rule[:rule_definition]) && self.send(rule[:rule_definition], pm, obj, rule[:rule_value])
      end
      matches_rule = matches == rules_and_actions[:rules].size
      yield(rules_and_actions) if matches_rule
    end
  end

  def apply_rules_and_actions(pm, obj = nil)
    return if pm.skip_rules
    matched_rules_ids = []
    self.apply_rules(pm, obj) do |rules_and_actions|
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
