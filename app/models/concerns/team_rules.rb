require 'active_support/concern'

module TeamRules
  extend ActiveSupport::Concern

  RULES = ['contains_keyword', 'has_less_than_x_words', 'title_matches_regexp', 'request_matches_regexp', 'type_is', 'tagged_as',
           'flagged_as', 'status_is', 'title_contains_keyword', 'item_titles_are_similar', 'item_images_are_similar', 'report_is_published',
           'report_is_paused']

  ACTIONS = ['send_to_trash', 'move_to_project', 'ban_submitter', 'copy_to_project', 'send_message_to_user', 'relate_similar_items']

  RULES_JSON_SCHEMA = File.read(File.join(Rails.root, 'public', 'rules_json_schema.json'))
  RULES_JSON_SCHEMA_VALIDATOR = JSON.parse(File.read(File.join(Rails.root, 'public', 'rules_json_schema_validator.json')))

  module Rules
    def has_less_than_x_words(pm, obj, value, _rule_id)
      return false unless obj.nil?
      smooch_message = get_smooch_message(pm)
      smooch_message.to_s.split(/\s+/).size < value.to_i
    end

    def contains_keyword(pm, obj, value, _rule_id)
      return false unless obj.nil?
      smooch_message = get_smooch_message(pm)
      return false if smooch_message.blank?
      text_contains_keyword(smooch_message, value)
    end

    def title_contains_keyword(pm, obj, value, _rule_id)
      return false unless obj.nil?
      text_contains_keyword(pm.title, value)
    end

    def text_contains_keyword(text, value)
      words = text.to_s.scan(/\w+/).to_a.map(&:downcase)
      keywords = value.to_s.split(',').map(&:strip).map(&:downcase)
      !(words & keywords).empty?
    end

    def get_smooch_message(pm)
      smooch_message = pm.smooch_message
      if smooch_message.nil?
        smooch_message = begin JSON.parse(pm.get_annotations('smooch').last.load.get_field_value('smooch_data').to_s) rescue {} end
      end
      smooch_message['text']
    end

    def title_matches_regexp(pm, obj, value, _rule_id)
      return false unless obj.nil?
      matches_regexp(pm.title, value)
    end

    def request_matches_regexp(pm, obj, value, _rule_id)
      return false unless obj.nil?
      smooch_message = get_smooch_message(pm)
      matches_regexp(smooch_message, value)
    end

    def matches_regexp(text, value)
      text ||= ''
      !text.match(/#{Regexp.new(value)}/).nil?
    end

    def type_is(pm, obj, value, _rule_id)
      obj.nil? && pm.report_type == value
    end

    def tagged_as(_pm, tag, value, _rule_id)
      tag.is_a?(Tag) && tag.tag_text == value
    end

    def status_is(_pm, status, value, _rule_id)
      status.is_a?(DynamicAnnotation::Field) && status.field_name == 'verification_status_status' && status.value == value
    end

    def item_titles_are_similar(pm, obj, value, rule_id)
      !pm.title.blank? && pm.report_type != 'uploadedimage' && items_are_similar('title', pm, obj, value, rule_id)
    end

    def item_images_are_similar(pm, obj, value, rule_id)
      pm.report_type == 'uploadedimage' && items_are_similar('image', pm, obj, value, rule_id)
    end

    def items_are_similar(type, pm, obj, value, rule_id)
      if obj.nil?
        value = value.to_s.gsub(/[^0-9]/, '').to_f / 100.0
        pm.alegre_similarity_thresholds ||= {}
        pm.alegre_similarity_thresholds[rule_id] ||= {}
        pm.alegre_similarity_thresholds[rule_id][type] = value.to_f if pm.alegre_similarity_thresholds[rule_id][type].to_f < value.to_f
        true
      else
        false
      end
    end

    def flagged_as(_pm, flag, json_value, _rule_id)
      value = JSON.parse(json_value)
      flag.is_a?(Dynamic) && flag.annotation_type == 'flag' && flag.get_field_value('flags')[value['flag'].to_s] >= value['threshold'].to_i
    end

    def report_is_published(_pm, report, _value, _rule_id)
      report_state_is(report, 'published')
    end

    def report_is_paused(_pm, report, _value, _rule_id)
      report_state_is(report, 'paused')
    end

    def report_state_is(report, state)
      report.is_a?(Dynamic) && report.annotation_type == 'report_design' && report.get_field_value('state') == state
    end
  end

  module Actions
    def send_to_trash(pm, _value, _rule_id)
      pm = ProjectMedia.find(pm.id)
      pm.archived = 1
      pm.skip_check_ability = true
      pm.save!
    end

    def ban_submitter(pm, _value, _rule_id)
      ::Bot::Smooch.ban_user(pm.smooch_message)
    end

    def move_to_project(pm, value, _rule_id)
      project = Project.where(team_id: self.id, id: value.to_i).last
      unless project.nil?
        pm = ProjectMedia.where(id: pm.id).last
        pm.previous_project_id = pm.project_id
        pm.project_id = project.id
        pm.skip_check_ability = true
        pm.save!
      end
    end

    def copy_to_project(pm, value, _rule_id)
      project = Project.where(team_id: self.id, id: value.to_i).last
      ProjectMediaProject.create!(project: project, project_media: pm) if !project.nil? && ProjectMediaProject.where(project_id: project.id, project_media_id: pm.id).last.nil?
    end

    def send_message_to_user(pm, value, _rule_id)
      Team.delay_for(1.second).send_message_to_user(self.id, pm.id, value)
    end

    def relate_similar_items(pm, _value, rule_id)
      Team.delay_for(1.second).relate_similar_items(pm.id, pm.alegre_similarity_thresholds[rule_id].to_json)
    end
  end

  module ClassMethods
    def relate_similar_items(pmid, thresholds_json)
      pm = ProjectMedia.where(id: pmid).last
      return if pm.nil?
      thresholds = JSON.parse(thresholds_json)
      similar_titles = Bot::Alegre.get_items_with_similar_title(pm, thresholds['title'].to_f) if thresholds['title']
      similar_images = Bot::Alegre.get_items_with_similar_image(pm, thresholds['image'].to_f) if thresholds['image']
      pm_ids = thresholds['title'] && thresholds['image'] ? (similar_titles & similar_images) : (similar_titles || similar_images)
      Bot::Alegre.add_relationships(pm, pm_ids.sort)
    end

    def send_message_to_user(team_id, pmid, value)
      team = Team.where(id: team_id).last
      return if team.nil?
      pm = ProjectMedia.where(id: pmid).last
      unless pm.nil?
        pm.get_annotations('smooch').find_each do |annotation|
          data = JSON.parse(annotation.load.get_field_value('smooch_data'))
          Bot::Smooch.get_installation('smooch_app_id', data['app_id']) if Bot::Smooch.config.blank?
          key = 'rule_action_send_message_' + Digest::MD5.hexdigest(value)
          message = CheckI18n.i18n_t(team, key, value, { locale: data['language'] })
          Bot::Smooch.send_message_to_user(data['authorId'], message)
        end
      end
    end
  end

  included do
    include ::TeamRules::Rules
    include ::TeamRules::Actions
    include ErrorNotification

    validate :rules_follow_schema, :rules_regular_expressions_are_valid
    after_save :update_rules_index, :upload_custom_rules_strings_to_transifex

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
    pm = ProjectMedia.new(project: Project.new(team_id: self.id), team: self, team_id: self.id)
    statuses = ::Workflow::Workflow.options(pm, pm.default_project_media_status_type)[:statuses]
    statuses = statuses.collect{ |st| { key: st.with_indifferent_access['id'], value: st.with_indifferent_access['label'] } }
    flags = DynamicAnnotation::AnnotationType.where(annotation_type: 'flag').last&.json_schema&.dig('properties', 'flags', 'required').to_a.collect{ |f| { key: f, value: I18n.t("flag_#{f}") } }
    likelihoods = (0..5).to_a.collect{ |n| { key: n, value: I18n.t("flag_likelihood_#{n}") } }

    {
      'actions' => {
        'action_value_move_to_project' => { title: I18n.t(:team_rule_destination), type: 'string', enum: projects },
        'action_value_copy_to_project' => { title: I18n.t(:team_rule_destination), type: 'string', enum: projects }
      },
      'rules' => {
        'rule_value_flagged_as' => { title: I18n.t(:team_rule_select_flag), type: 'string', enum: flags },
        'rule_value_flag_threshold' => { title: I18n.t(:team_rule_type_flag_threshold), type: 'string', enum: likelihoods },
        'rule_value_similar_titles' => { title: I18n.t(:team_rule_type_title_threshold), type: 'integer' },
        'rule_value_similar_images' => { title: I18n.t(:team_rule_type_image_threshold), type: 'integer' },
        'rule_value_max_number_of_words' => { title: I18n.t(:team_rule_type_number), type: 'string' },
        'rule_value_type_is' => { title: I18n.t(:team_rule_select_type), type: 'string', enum: types },
        'rule_value_tagged_as' => { title: I18n.t(:team_rule_select_tag), type: 'string', enum: tags },
        'rule_value_status_is' => { title: I18n.t(:team_rule_select_status), type: 'string', enum: statuses },
        'rule_value_matches_regexp' => { title: I18n.t(:team_rule_type_regexp), type: 'string' }
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
      rule_id = Team.rule_id(rules_and_actions)
      matches = 0
      rules_and_actions[:rules].each do |rule|
        matches += 1 if ::TeamRules::RULES.include?(rule[:rule_definition]) && self.send(rule[:rule_definition], pm, obj, rule[:rule_value], rule_id)
      end
      matches_rule = matches == rules_and_actions[:rules].size
      yield(rules_and_actions) if matches_rule
    end
  end

  def apply_rules_and_actions(pm, obj = nil)
    return if pm.skip_rules
    begin
      matched_rules_ids = []
      self.apply_rules(pm, obj) do |rules_and_actions|
        rule_id = Team.rule_id(rules_and_actions)
        rules_and_actions[:actions].each do |action|
          if ::TeamRules::ACTIONS.include?(action[:action_definition])
            pm.skip_check_ability = true
            self.send(action[:action_definition], pm, action[:action_value], rule_id)
            pm.skip_check_ability = false
          end
          matched_rules_ids << rule_id
        end
      end
      pm.update_elasticsearch_doc(['rules'], { 'rules' => matched_rules_ids }, pm)
    rescue StandardError => e
      Airbrake.notify(e, params: { team: self.name, project_media_id: pm.id, method: 'apply_rules_and_actions' }) if Airbrake.configured?
      Rails.logger.info "[Team Rules] Exception when applying rules to project media #{pm.id} for team #{self.id}"
    end
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
    errors.add(:base, I18n.t(:team_rule_json_schema_validation)) if !self.get_rules.blank? && !JSON::Validator.validate(RULES_JSON_SCHEMA_VALIDATOR, self.get_rules)
  end

  def update_rules_index
    if self.rules_changed?
      Rails.cache.write("cancel_rules_indexing_for_team_#{self.id}", 1) if Rails.cache.read("rules_indexing_in_progress_for_team_#{self.id}")
      RulesIndexWorker.perform_in(5.seconds, self.id)
    end
  end

  def rules_regular_expressions_are_valid
    unless self.get_rules.blank?
      self.get_rules.each do |rule|
        rule['rules'].to_a.each do |condition|
          if condition['rule_definition'] =~ /regexp/
            begin
              Regexp.new(condition['rule_value'])
            rescue RegexpError => e
              errors.add(:base, I18n.t(:team_rule_regexp_invalid, { error: e.message }))
            end
          end
        end
      end
    end
  end

  def upload_custom_rules_strings_to_transifex
    strings = {}
    unless self.get_rules.blank?
      self.get_rules.each do |rule|
        rule['actions'].to_a.each do |action|
          if action['action_definition'] == 'send_message_to_user'
            key = Digest::MD5.hexdigest(action['action_value'])
            strings[key] = action['action_value']
          end
        end
      end
    end
    CheckI18n.upload_custom_strings_to_transifex_in_background(self, 'rule_action_send_message', strings) unless strings.blank?
  end
end
