class Dynamic < ActiveRecord::Base
  include AnnotationBase

  mount_uploaders :file, ImageUploader
  serialize :file, JSON

  attr_accessor :set_fields, :set_attribution, :action, :action_data

  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  has_many :fields, class_name: 'DynamicAnnotation::Field', foreign_key: 'annotation_id', primary_key: 'id', dependent: :destroy

  before_validation :update_attribution, :update_timestamp, :set_data
  after_create :create_fields
  after_update :update_fields
  after_commit :apply_rules_and_actions, on: [:create]
  after_commit :send_slack_notification, on: [:create, :update]
  after_commit :add_elasticsearch_dynamic, on: :create
  after_commit :update_elasticsearch_dynamic, on: :update
  after_commit :destroy_elasticsearch_dynamic_annotation, on: :destroy

  validate :annotation_type_exists
  validate :mandatory_fields_are_set, on: :create
  validate :attribution_contains_only_team_members
  validate :fields_against_json_schema

  def slack_notification_message
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
      event: event
    })
  end

  def slack_notification_message_task_response
    params = self.slack_params_task_response
    params[:task].slack_notification_message(params)
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

  def get_elasticsearch_options_dynamic
    options = {}
    method = "get_elasticsearch_options_dynamic_annotation_#{self.annotation_type}"
    if self.respond_to?(method)
      options = self.send(method)
    elsif self.fields.count > 0
      options = {keys: ['indexable'], data: {}}
    end
    options
  end

  def create_field(name, value)
    f = DynamicAnnotation::Field.new
    f.skip_check_ability = true
    f.disable_es_callbacks = self.disable_es_callbacks
    f.field_name = name
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
    return if self.disable_es_callbacks
    op = 'create_or_update' if annotation_type == 'smooch'
    options = get_elasticsearch_options_dynamic
    options.merge!({op: op, nested_key: 'dynamics'})
    add_update_nested_obj(options)
  end

  def destroy_elasticsearch_dynamic_annotation
    destroy_es_items('dynamics')
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
        f = fields.select{ |x| x.field_name == field }.last || create_field(field, nil)
        f.value = value
        f.save!
      end
    end
  end

  def set_data
    self.data = self.data.merge(JSON.parse(self.set_fields)) if !self.set_fields.blank? && !self.json_schema.blank?
  end

  def mandatory_fields_are_set
    if !self.set_fields.blank? && self.annotation_type != 'dynamic'
      annotation_type = DynamicAnnotation::AnnotationType.where(annotation_type: self.annotation_type).last
      fields_set = JSON.parse(self.set_fields).keys
      mandatory_fields = annotation_type.schema.reject{ |instance| instance.optional }.map(&:name)
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
      team_id = self.annotated.project ? self.annotated.project.team_id : self.annotated.team_id
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
    if self.annotated_type == 'ProjectMedia' && self.annotation_type == 'flag'
      team = self.annotated.team
      team.apply_rules_and_actions(self.annotated, self) unless team.nil?
    end
  end
end
