class Dynamic < ApplicationRecord
  class DuplicateFieldError < ActiveRecord::RecordNotUnique; end

  include AnnotationBase

  mount_uploaders :file, ImageUploader
  serialize :file, JSON

  attr_accessor :set_fields, :set_attribution, :action, :action_data, :bypass_status_publish_check

  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type', optional: true
  has_many :fields, class_name: 'DynamicAnnotation::Field', foreign_key: 'annotation_id', primary_key: 'id', dependent: :destroy

  before_validation :update_attribution, :update_timestamp, :set_data
  after_create :create_fields
  after_update :update_fields
  after_commit :apply_rules_and_actions, on: [:create, :update], if: proc { |d| ['flag', 'report_design', 'language', 'task_response_single_choice', 'task_response_multiple_choice', 'task_response_free_text', 'extracted_text'].include?(d.annotation_type) }
  after_commit :dynamic_send_slack_notification, on: [:create, :update]
  after_commit :add_elasticsearch_dynamic, on: :create
  after_commit :update_elasticsearch_dynamic, on: :update
  after_commit :destroy_elasticsearch_dynamic_annotation, on: :destroy

  validate :annotation_type_exists
  validate :mandatory_fields_are_set, on: :create
  validate :attribution_contains_only_team_members
  validate :fields_against_json_schema

  def slack_notification_message(_event = nil)
    annotation_type = self.annotation_type =~ /^task_response/ ? 'task_response' : self.annotation_type
    method = "slack_notification_message_#{annotation_type}"
    if self.respond_to?(method)
      self.send(method)
    end
  end

  def slack_params_task_response
    response = self.values(['response'], '')['response']
    task = Task.find(self.annotated_id)
    event = self.previous_changes.keys.include?('id') ? 'answer_create' : 'answer_edit'
    task.slack_params.merge({
      description: Bot::Slack.to_slack(response, false),
      attribution: User.where('id IN (:ids)', { :ids => self.attribution.to_s.split(',') })&.collect { |u| u.name }&.to_sentence,
      task: task,
      event: event,
      answer: response
    })
  end

  def slack_notification_message_task_response
    params = self.slack_params_task_response
    params[:task].slack_notification_message(params)
  end

  # TODO: Sawy::remove this method and handle slack notification for sources
  def dynamic_send_slack_notification
    ignore_notification = self.annotated_type == 'Task' && self.annotated.present? && self.annotated.annotated_type == 'Source'
    self.send_slack_notification unless ignore_notification
  end

  def data
    fields = self.fields
    if fields.empty?
      self.read_attribute(:data)
    else
      {
        'fields' => fields.to_a,
        'indexable' => fields.map(&:value).select{ |v| v.is_a?(String) }.join('. ')
      }.with_indifferent_access
    end
  end

  # Given field names, return a hash of the corresponding field values.
  # Initialize the hash with the given default value.
  def values(fields, default)
    values = Hash[fields.product([default])]

    # Cache the fields for performance.
    @fields ||= self.fields

    @fields.each do |field|
      fields.each do |f|
        values[f] = field.to_s if field.field_name =~ /^#{Regexp.escape(f)}/
      end
    end
    values
  end

  def get_field(name)
    self.get_fields.select{ |f| f.field_name == name.to_s }.first
  end

  def get_field_value(name)
    self.get_field(name)&.value
  end

  def create_field(name, value)
    f = DynamicAnnotation::Field.new
    f.skip_check_ability = true
    f.disable_es_callbacks = self.disable_es_callbacks || value.blank?
    f.field_name = name
    value.gsub!('\u0000', '') if value.is_a?(String) # Avoid PG::UntranslatableCharacter exception
    f.value = value
    f.annotation_id = self.id
    f
  end

  def json_schema
    self.annotation_type_object.json_schema if self.annotation_type_object && self.annotation_type_object.json_schema_enabled?
  end

  private

  def add_elasticsearch_dynamic
    add_update_elasticsearch_dynamic('create')
  end

  def update_elasticsearch_dynamic
    add_update_elasticsearch_dynamic('update')
  end

  def add_update_elasticsearch_dynamic(op)
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    handle_elasticsearch_response(op)
    handle_annotated_by(op)
    handle_extracted_text(op)
    handle_report_fields
  end

  def handle_elasticsearch_response(op)
    if self.annotated_type == 'Task' && self.annotation_type =~ /^task_response/
      task = self.annotated
      # Index response for team tasks or free text tasks
      if task&.annotated_type == 'ProjectMedia' && (task.team_task_id || self.annotation_type == 'task_response_free_text')
        pm = task.project_media
        return if pm.nil?
        if op == 'destroy'
          handle_destroy_response(task, pm.id)
        else
          # OP will be update for choices tasks as it's already created in TASK model(add_elasticsearch_task)
          op = self.annotation_type =~ /choice/ ? 'update' : op
          keys = %w(id team_task_id value field_type fieldset date_value numeric_value)
          self.add_update_nested_obj({ op: op, pm_id: pm.id, nested_key: 'task_responses', keys: keys })
          self.update_recent_activity(pm) if User.current.present?
        end
      end
    end
  end

  def handle_extracted_text(op)
    if self.annotated_type == 'ProjectMedia' && self.annotation_type == 'extracted_text'
      pm = self.annotated
      unless pm.nil?
        value = op == 'destroy' ? '' : self.data['text']
        pm.update_elasticsearch_doc(['extracted_text'], { 'extracted_text' => value }, pm.id, true)
      end
    end
  end

  def handle_report_fields
    if self.annotated_type == 'ProjectMedia' && self.annotation_type == 'report_design'
      data = { 'report_published_at' => self.data['last_published'], 'report_language' => self.report_design_field_value('language') }
      self.update_elasticsearch_doc(data.keys, data, self.annotated_id, true)
    end
  end

  def handle_annotated_by(op)
    if self.annotated_type == 'Task' && self.annotation_type =~ /^task_response/
      task = self.annotated
      if task&.annotated_type == 'ProjectMedia'
        pm = task.project_media
        return if pm.nil?
        key = "project_media:annotated_by:#{pm.id}"
        uids = []
        if Rails.cache.exist?(key)
          uids = Rails.cache.read(key) || []
        else
          Annotation.select('a2.*')
          .where(annotation_type: 'task', annotated_type: 'ProjectMedia', annotated_id: pm.id)
          .joins("INNER JOIN annotations a2 on annotations.id = a2.annotated_id")
          .where("a2.annotation_type LIKE ?", 'task_response_%').find_each do |r|
            uids << r['annotator_id']
          end
        end
        if op == 'destroy'
          uids -= [self.annotator_id]
        else
          uids << self.annotator_id
        end
        uids.uniq!
        Rails.cache.write(key, uids)
        task.update_elasticsearch_doc(['annotated_by'], { 'annotated_by' => uids }, pm.id, true)
      end
    end
  end

  def handle_destroy_response(task, pm_id)
    # destroy choice should reset the answer to nil to keep search for ANY/NON value in ES
    # so it'll be update action for choice
    # otherwise delete the field from ES
    if self.annotation_type =~ /choice/
      task.add_update_elasticsearch_task('update')
    else
      task.destroy_es_items('task_responses', 'destroy_doc_nested', pm_id)
    end
  end

  def destroy_elasticsearch_dynamic_annotation
    # destroy task response
    handle_elasticsearch_response('destroy')
    handle_extracted_text('destroy')
    handle_annotated_by('destroy')
  end

  def annotation_type_exists
    errors.add(:annotation_type, I18n.t('errors.messages.annotation_type_does_not_exist')) if self.annotation_type != 'dynamic' && DynamicAnnotation::AnnotationType.where(annotation_type: self.annotation_type).last.nil?
  end

  def create_fields
    if !self.set_fields.blank? && self.json_schema.blank?
      @fields = []
      data = JSON.parse(self.set_fields)
      data.each do |field_name, value|
        next unless DynamicAnnotation::FieldInstance.where(name: field_name).exists?
        value ||= ""
        f = create_field(field_name, value)
        f.save!
        @fields << f
      end
    end
  end

  def update_fields
    if !self.set_fields.blank? && self.json_schema.blank?
      fields = self.fields
      data = JSON.parse(self.set_fields)
      data.each do |field, value|
        next if value.blank?
        f = fields.select{ |x| x.field_name == field }.last || create_field(field, nil)
        f.value = value
        f.bypass_status_publish_check = self.bypass_status_publish_check
        f.skip_check_ability = self.skip_check_ability unless self.skip_check_ability.nil?
        begin
          f.save!
        rescue ActiveRecord::RecordNotUnique => e
          raise DuplicateFieldError.new(e)
        end
      end
    end
  end

  def set_data
    unless self.set_fields.blank? || self.json_schema.blank?
      self.data ||= {}.with_indifferent_access
      self.data = begin self.data.merge(JSON.parse(self.set_fields)).with_indifferent_access rescue {}.with_indifferent_access end
    end
  end

  def mandatory_fields_are_set
    if !self.set_fields.blank? && self.annotation_type != 'dynamic'
      annotation_type = DynamicAnnotation::AnnotationType.where(annotation_type: self.annotation_type).last
      fields_set = begin JSON.parse(self.set_fields)&.keys rescue nil end
      fields_set ||= []
      mandatory_fields = begin annotation_type.schema.reject{ |instance| instance.optional }.map(&:name) rescue [] end
      errors.add(:base, I18n.t('errors.messages.annotation_mandatory_fields')) unless (mandatory_fields - fields_set).empty?
    end
  end

  def set_annotator
    self.annotator = User.current if !User.current.nil? && (self.annotator.nil? || ((!self.annotator.is_a?(User) || !self.annotator.role?(:annotator)) && self.annotation_type_object.singleton))
  end

  def update_timestamp
    self.updated_at = Time.now
  end

  def update_attribution
    if self.annotation_type =~ /^task_response/
      if self.set_attribution.blank?
        user_ids = self.attribution.to_s.split(',')
        user_ids << User.current.id unless User.current.nil?
        self.attribution = user_ids.uniq.join(',')
      else
        self.attribution = self.set_attribution
      end
    end
  end

  def attribution_contains_only_team_members
    unless self.set_attribution.blank?
      team_id = self.annotated.team&.id
      members_ids = TeamUser.where(team_id: team_id, status: 'member').map(&:user_id).map(&:to_i)
      invalid = []
      self.set_attribution.split(',').each do |uid|
        invalid << uid if !members_ids.include?(uid.to_i) && User.where(id: uid.to_i, is_admin: true).last.nil?
      end
      errors.add(:base, I18n.t('errors.messages.invalid_attribution')) unless invalid.empty?
    end
  end

  def fields_against_json_schema
    begin
      JSON::Validator.validate!(self.json_schema, self.read_attribute(:data)) unless self.json_schema.blank?
    rescue JSON::Schema::ValidationError => e
      errors.add(:base, e.message)
    end
  end

  def apply_rules_and_actions
    team = self.annotated&.team
    unless team.nil?
      # Evaluate only the rules that contain a condition that matches this report, language, flag or task answer
      annotated = self.annotated_type == 'ProjectMedia' ? self.annotated : self.annotated.annotated
      if annotated.class.name == 'ProjectMedia'
        rule_ids = get_rule_ids
        team.apply_rules_and_actions(annotated, rule_ids || [])
      end
    end
  end

  def get_rule_ids
    rule_ids = case self.annotation_type
               when 'report_design'
                 self.send(:rule_ids_for_report)
               when 'flag'
                 self.send(:rule_ids_for_flag)
               when 'language'
                 self.send(:rule_ids_for_language)
               when 'task_response_single_choice', 'task_response_multiple_choice'
                 self.send(:rule_ids_for_choice_task_response)
               when 'task_response_free_text'
                 self.send(:rule_ids_for_text_task_response)
               when 'extracted_text'
                 self.send(:rule_ids_for_extracted_text)
               end
    rule_ids
  end

  def rule_ids_for_report
    self.annotated.team.get_rules_that_match_condition do |condition, _value|
      (condition == 'report_is_published' && self.get_field_value('state') == 'published') || (condition == 'report_is_paused' && self.get_field_value('state') == 'paused')
    end
  end

  def rule_ids_for_flag
    self.annotated.team.get_rules_that_match_condition do |condition, value|
      condition == 'flagged_as' && self.get_field_value('flags')[value['flag'].to_s] >= value['threshold'].to_i
    end
  end

  def rule_ids_for_language
    self.annotated.team.get_rules_that_match_condition do |condition, value|
      condition == 'item_language_is' && self.get_field_value('language') == value
    end
  end

  def rule_ids_for_choice_task_response
    self.annotated.annotated.team.get_rules_that_match_condition do |condition, value|
      response = self.annotation_type == 'task_response_single_choice' ? self.get_field('response_single_choice') : self.get_field('response_multiple_choice')
      condition == "field_from_fieldset_#{self.annotated.fieldset}_value_is" && response.selected_values_from_task_answer.include?(value['value'])
    end
  end

  def rule_ids_for_text_task_response
    return [] unless self.annotated_type == 'Task'
    self.annotated.annotated.team.get_rules_that_match_condition do |condition, value|
      condition == "field_from_fieldset_#{self.annotated.fieldset}_value_contains_keyword" && self.annotated.annotated.team.text_contains_keyword(self.get_field_value('response_free_text'), value['value'])
    end
  end

  def rule_ids_for_extracted_text
    team = self.annotated.team
    team.get_rules_that_match_condition do |condition, value|
      text = self.get_field_value('text')
      condition == 'extracted_text_contains_keyword' && team.text_contains_keyword(text, value)
    end
  end
end
