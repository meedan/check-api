require 'active_support/concern'

module TeamRules
  extend ActiveSupport::Concern

  RULES = ['contains_keyword', 'has_less_than_x_words', 'title_matches_regexp', 'request_matches_regexp', 'type_is', 'tagged_as',
           'flagged_as', 'status_is', 'title_contains_keyword', 'item_titles_are_similar', 'item_images_are_similar', 'report_is_published',
           'report_is_paused', 'item_language_is', 'item_user_is', 'item_is_read', 'item_is_assigned_to_user',
            'extracted_text_contains_keyword']

  ACTIONS = ['send_to_trash', 'ban_submitter', 'add_tag', 'add_warning_cover']

  RULES_JSON_SCHEMA = File.read(File.join(Rails.root, 'public', 'rules_json_schema.json'))

  def rules=(rules)
    self.send(:set_rules, JSON.parse(rules))
  end

  module Rules
    def has_less_than_x_words(pm, value, _rule_id)
      return false unless pm.media&.type == 'Claim'
      smooch_message = get_smooch_message(pm)
      return false if smooch_message['text'].blank?
      #TODO: Consider using Bot::Alegre.number_of_words
      smooch_message['text'].to_s.gsub(Bot::Smooch::MESSAGE_BOUNDARY, '').split(/\s+/).select{ |w| (w =~ /^[0-9]+$/).nil? }.size <= value.to_i
    end

    def contains_keyword(pm, value, _rule_id)
      smooch_message = get_smooch_message(pm)
      return false if smooch_message['text'].blank?
      text_contains_keyword(smooch_message['text'], value)
    end

    def title_contains_keyword(pm, value, _rule_id)
      text_contains_keyword(pm.title, value) || text_contains_keyword(pm.description, value)
    end

    def text_contains_keyword(text, value)
      words = text.to_s.scan(/\w+/).to_a.map(&:downcase).reject{ |w| w.blank? }
      keywords = value.to_s.split(',').map(&:strip).map(&:downcase).reject{ |w| w.blank? }
      contains = !(words & keywords).empty?
      # Special case to match keywords with spaces
      unless contains
        keywords.each do |keyword|
          contains = !text.to_s.downcase.match(/(^|[^[:alpha:]])#{keyword}($|[^[:alpha:]])/).nil? if !contains && keyword.to_s.match(' ')
        end
      end
      contains
    end

    def get_smooch_message(pm)
      smooch_message = pm.smooch_message
      smooch_message.nil? ? pm.tipline_requests.last&.smooch_data.to_h : smooch_message
    end

    def title_matches_regexp(pm, value, _rule_id)
      matches_regexp(pm.title, value)
    end

    def request_matches_regexp(pm, value, _rule_id)
      smooch_message = get_smooch_message(pm)
      matches_regexp(smooch_message['text'], value)
    end

    def matches_regexp(text, value)
      text ||= ''
      !text.match(/#{Regexp.new(value)}/).nil?
    end

    def type_is(pm, value, _rule_id)
      pm.report_type == value
    end

    def tagged_as(pm, value, _rule_id)
      pm.get_annotations('tag').map(&:load).select{ |tag| tag.tag_text == value }.size > 0
    end

    def status_is(pm, value, _rule_id)
      pm.last_status == value
    end

    def item_titles_are_similar(pm, value, rule_id)
      !pm.title.blank? && pm.report_type != 'uploadedimage' && items_are_similar('title', pm, value, rule_id)
    end

    def item_images_are_similar(pm, value, rule_id)
      pm.report_type == 'uploadedimage' && items_are_similar('image', pm, value, rule_id)
    end

    def items_are_similar(type, pm, value, rule_id)
      value = value.to_s.gsub(/[^0-9]/, '').to_f / 100.0
      pm.alegre_similarity_thresholds ||= {}
      pm.alegre_similarity_thresholds[rule_id] ||= {}
      pm.alegre_similarity_thresholds[rule_id][type] = value.to_f if pm.alegre_similarity_thresholds[rule_id][type].to_f < value.to_f
      true
    end

    def flagged_as(pm, value, _rule_id)
      range_condition = [value['threshold'].to_i - 1, value['threshold'].to_i]
      pm.get_annotations('flag').map(&:load).select{ |flag| range_condition.include?(flag.get_field_value('flags')[value['flag'].to_s]) }.size > 0
    end

    def report_is_published(pm, _value, _rule_id)
      report_state_is(pm, 'published')
    end

    def report_is_paused(pm, _value, _rule_id)
      report_state_is(pm, 'paused')
    end

    def report_state_is(pm, state)
      pm.get_annotations('report_design').map(&:load).select{ |report| report.get_field_value('state') == state }.size > 0
    end

    def item_language_is(pm, value, _rule_id)
      pm.get_dynamic_annotation('language')&.get_field_value('language') == value
    end

    def item_user_is(pm, value, _rule_id)
      pm.user_id == value.to_i
    end

    def item_is_read(pm, _value, _rule_id)
      pm.read
    end

    def field_value_is(pm, value, _rule_id)
      pm.get_annotations('task').count > 0 && pm.selected_value_for_task?(value['team_task_id'].to_i, value['value'].to_s)
    end

    def item_is_assigned_to_user(pm, value, _rule_id)
      status = pm.last_status_obj
      status && Assignment.exists?(assigned_type: 'Annotation', assigned_id: status.id, user_id: value.to_i)
    end

    def extracted_text_contains_keyword(pm, value, _rule_id)
      text_contains_keyword(pm.extracted_text, value)
    end

    def field_contains_keyword(pm, value, _rule_id)
      field_value_that_contains_keyword = pm.get_annotations('task').find do |annotation|
        task = annotation.becomes(Task)
        task.type == 'free_text' && task.task.team_task_id.to_i == value['team_task_id'].to_i && text_contains_keyword(task.first_response, value['value'].to_s)
      end
      !field_value_that_contains_keyword.nil?
    end
  end

  module Actions
    def send_to_trash(pm, _value, _rule_id)
      pm = ProjectMedia.find_by_id(pm.id)
      unless pm.nil? || pm.archived == CheckArchivedFlags::FlagCodes::TRASHED
        pm.archived = CheckArchivedFlags::FlagCodes::TRASHED
        pm.skip_check_ability = true
        pm.save!
        CheckNotification::InfoMessages.send('sent_to_trash_by_rule', item_title: pm.title)
      end
    end

    def ban_submitter(pm, _value, _rule_id)
      smooch_message = get_smooch_message(pm)
      unless smooch_message.blank?
        ::Bot::Smooch.ban_user(smooch_message)
        CheckNotification::InfoMessages.send('banned_submitter_by_rule', item_title: pm.title)
      end
    end

    def add_tag(pm, value, _rule_id)
      tag_text = TagText.where(text: value, team_id: pm.team_id).last
      return if tag_text.nil?
      tag = Tag.new
      tag.annotated = pm
      tag.tag = tag_text.id
      tag.skip_check_ability = true
      CheckNotification::InfoMessages.send('tagged_by_rule', item_title: pm.title, tag: tag_text.text) if tag.save
    end

    def add_warning_cover(pm, _value, _rule_id)
      flag = pm.annotations('flag').last&.load
      unless flag.nil?
        RequestStore.store[:skip_rules] = true
        flag.set_fields = { show_cover: true }.to_json
        flag.skip_check_ability = true
        flag.save!
        RequestStore.store[:skip_rules] = false
        CheckNotification::InfoMessages.send('add_warning_cover_by_rule', item_title: pm.title)
      end
    end
  end

  included do
    include ::TeamRules::Rules
    include ::TeamRules::Actions

    validate :rules_names, :rules_regular_expressions_are_valid

    def self.rule_id(rule)
      rule.with_indifferent_access[:name].parameterize.tr('-', '_')
    end
  end

  def rules_json_schema
    pm = ProjectMedia.new(team_id: self.id)
    statuses_objs = ::Workflow::Workflow.options(pm, pm.default_project_media_status_type)[:statuses]
    choice_field_objs = self.team_tasks.where(associated_type: 'ProjectMedia').where("task_type LIKE '%_choice'").to_a.map(&:as_json).group_by{ |tt| tt[:fieldset] }
    text_field_objs = self.team_tasks.where(associated_type: 'ProjectMedia').where(task_type: 'free_text').to_a.map(&:as_json).group_by{ |tt| tt[:fieldset] }
    namespace = OpenStruct.new({
      types: ['Claim', 'Link', 'UploadedImage', 'UploadedVideo'].collect{ |t| { key: t.downcase, value: I18n.t("team_rule_type_is_#{t.downcase}") } },
      tags: self.tag_texts.collect{ |t| { key: t.text, value: t.text } },
      statuses: statuses_objs.collect{ |st| { key: st.with_indifferent_access['id'], value: st.with_indifferent_access['label'] } },
      flags: DynamicAnnotation::AnnotationType.where(annotation_type: 'flag').last&.json_schema&.dig('properties', 'flags', 'required').to_a
      .reject{ |f| ['spam', 'racy', 'spoof'].include?(f) } # Hide some flags
             .collect{ |f| { key: f, value: I18n.t("flag_#{f}") } },
      likelihoods: [5, 3, 1].collect{ |n| { key: n, value: I18n.t("flag_likelihood_#{n}") } },
      languages: self.get_languages.to_a.collect{ |l| { key: l, value: CheckCldr.language_code_to_name(l) } },
      users: self.users.to_a.sort_by{ |u| u.name }.collect{ |u| { key: u.id, value: u.name } },
      choice_fields: choice_field_objs.deep_dup.each{ |_fs, tts| tts.collect!{ |tt| { key: tt[:id], value: tt[:label] } } },
      choice_field_values: choice_field_objs.deep_dup.each{ |_fs, tts| tts.collect!{ |tt| [tt[:id], tt[:options].reject{ |ro| ro['other'] }.collect{ |o| o.with_indifferent_access['label'] }.collect{ |l| { key: l, value: l } }] } },
      text_fields: text_field_objs.deep_dup.each{ |_fs, tts| tts.collect!{ |tt| { key: tt[:id], value: tt[:label] } } },
      choice_fieldsets: self.get_fieldsets.to_a.collect{ |f| f[:identifier] }.reject{ |f| !choice_field_objs.keys.include?(f) },
      text_fieldsets: self.get_fieldsets.to_a.collect{ |f| f[:identifier] }.reject{ |f| !text_field_objs.keys.include?(f) }
    })
    ERB.new(RULES_JSON_SCHEMA).result(namespace.instance_eval { binding })
  end

  def rules_conditions
    rules = ::TeamRules::RULES.clone
    # Generate rules for each fieldset, dynamically
    self.get_fieldsets.to_a.each do |fieldset|
      # Selected value
      name = "field_from_fieldset_#{fieldset[:identifier]}_value_is"
      rules << name
      self.class.send(:define_method, name) do |pm, value, rule_id|
        self.field_value_is(pm, value, rule_id)
      end

      # Text contains keyword
      name = "field_from_fieldset_#{fieldset[:identifier]}_value_contains_keyword"
      rules << name
      self.class.send(:define_method, name) do |pm, value, rule_id|
        self.field_contains_keyword(pm, value, rule_id)
      end
    end
    rules
  end

  def matches_group(group, pm, rule_id)
    matches = 0
    group[:conditions].each do |condition|
      matches += 1 if self.rules_conditions.include?(condition[:rule_definition]) && self.send(condition[:rule_definition], pm, condition[:rule_value], rule_id)
    end
    self.matches(group[:operator], matches, group[:conditions].size)
  end

  def matches(operator, matches, total)
    ((operator == 'and' && matches == total) || (operator == 'or' && matches > 0))
  end

  def apply_rules(pm, only_rule_ids = nil)
    all_rules_and_actions = self.get_rules || []
    all_rules_and_actions.map(&:with_indifferent_access).each do |rules_and_actions|
      rule_id = Team.rule_id(rules_and_actions)
      next if !only_rule_ids.nil? && !only_rule_ids.include?(rule_id)
      matches = 0
      rules = rules_and_actions[:rules]
      groups = rules[:groups]
      groups.each do |group|
        matches += 1 if matches_group(group, pm, rule_id)
      end
      matches_rule = self.matches(rules[:operator], matches, groups.size)
      yield(rules_and_actions) if matches_rule
    end
  end

  def get_rules_that_match_condition
    return [] if self.get_rules.blank?
    rule_ids = []
    self.get_rules.each do |rule|
      rule.with_indifferent_access[:rules][:groups].each do |group|
        group[:conditions].each do |condition|
          rule_ids << Team.rule_id(rule) if yield(condition[:rule_definition], condition[:rule_value])
        end
      end
    end
    rule_ids.uniq
  end

  def apply_rules_and_actions(pm, only_rule_ids = nil)
    return if pm.skip_rules || RequestStore.store[:skip_rules]
    begin
      matched_rules_ids = []
      self.apply_rules(pm, only_rule_ids) do |rules_and_actions|
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
    rescue StandardError => e
      CheckSentry.notify(e, team: self.name, project_media_id: pm.id, method: 'apply_rules_and_actions')
      Rails.logger.info "[Team Rules] Exception when applying rules to project media #{pm.id} for team #{self.id}"
    end
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

  def rules_names
    names = []
    unless self.get_rules.blank?
      self.get_rules.each do |rule|
        names << rule.with_indifferent_access['name']
      end
    end
    errors.add(:base, I18n.t(:team_rule_names_invalid)) if !names.select{ |n| n.blank? }.empty? || names.uniq.size != names.size
  end

  def rules_regular_expressions_are_valid
    unless self.get_rules.blank?
      self.get_rules.each do |rule|
        rule.with_indifferent_access['rules']['groups'].to_a.each do |group|
          group['conditions'].each do |condition|
            if condition['rule_definition'] =~ /regexp/
              begin
                Regexp.new(condition['rule_value'])
              rescue RegexpError => e
                errors.add(:base, I18n.t(:team_rule_regexp_invalid, **{ error: e.message }))
              end
            end
          end
        end
      end
    end
  end
end
