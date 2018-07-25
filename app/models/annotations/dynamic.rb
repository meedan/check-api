class Dynamic < ActiveRecord::Base
  include AnnotationBase

  attr_accessor :set_fields, :set_attribution

  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  has_many :fields, class_name: 'DynamicAnnotation::Field', foreign_key: 'annotation_id', primary_key: 'id', dependent: :destroy

  before_validation :update_attribution, :update_timestamp
  after_create :create_fields
  after_update :update_fields
  after_commit :send_slack_notification, on: [:create, :update]
  after_commit :add_elasticsearch_dynamic, on: :create
  after_commit :update_elasticsearch_dynamic, on: :update
  after_commit :destroy_elasticsearch_dynamic_annotation, on: :destroy

  validate :annotation_type_exists
  validate :mandatory_fields_are_set, on: :create
  validate :attribution_contains_only_team_members

  def slack_notification_message
    annotation_type = self.annotation_type =~ /^task_response/ ? 'task_response' : self.annotation_type
    method = "slack_notification_message_#{annotation_type}"
    if (!self.set_fields.blank? || self.assigned_to_id != self.previous_assignee) && self.respond_to?(method)
      self.send(method)
    end
  end

  def slack_notification_message_task_response
    self.slack_answer_task_message
  end

  def slack_answer_task_message
    response, note, task = self.values(['response', 'note', 'task'], '').values_at('response', 'note', 'task')
    task = Task.find(task).label

    note = I18n.t(:slack_answer_task_note, {note: Bot::Slack.to_slack_quote(note)}) unless note.blank?
    I18n.t(:slack_answer_task,
      user: Bot::Slack.to_slack(User.current.name),
      url: Bot::Slack.to_slack_url(self.annotated_client_url, task),
      project: Bot::Slack.to_slack(self.annotated.project.title),
      response: Bot::Slack.to_slack_quote(response),
      answer_note: note
    )
  end

  def data
    fields = self.fields
    {
      'fields' => fields.to_a,
      'indexable' => fields.map(&:value).select{ |v| v.is_a?(String) }.join('. ')
    }.with_indifferent_access
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
    self.get_fields.select{ |f| f['field_name'] == name.to_s }.first
  end

  def get_field_value(name)
    field = self.get_field(name)
    field.nil? ? nil : field.value
  end

  def add_elasticsearch_dynamic
    add_update_elasticsearch_dynamic('create')
  end

  private

  def update_elasticsearch_dynamic
    add_update_elasticsearch_dynamic('update')
  end

  def add_update_elasticsearch_dynamic(op)
    skip_types = ['verification_status', 'translation_status']
    return if self.disable_es_callbacks || skip_types.include?(self.annotation_type)
    method = "add_update_elasticsearch_dynamic_annotation_#{self.annotation_type}"
    if self.respond_to?(method)
      self.send(method, op)
    elsif self.fields.count > 0
      add_update_nested_obj({op: op, nested_key: 'dynamics', keys: ['indexable']})
    end
  end

  def destroy_elasticsearch_dynamic_annotation
    destroy_es_items('dynamics')
  end

  def annotation_type_exists
    errors.add(:annotation_type, 'does not exist') if self.annotation_type != 'dynamic' && DynamicAnnotation::AnnotationType.where(annotation_type: self.annotation_type).last.nil?
  end

  def create_fields
    unless self.set_fields.blank?
      @fields = []
      data = JSON.parse(self.set_fields)
      data.each do |field_name, value|
        next unless DynamicAnnotation::FieldInstance.where(name: field_name).exists?
        f = DynamicAnnotation::Field.new
        f.skip_check_ability = true
        f.disable_es_callbacks = self.disable_es_callbacks
        f.field_name = field_name
        f.value = value
        f.annotation_id = self.id
        f.save!
        @fields << f
      end
    end
  end

  def update_fields
    unless self.set_fields.blank?
      data = JSON.parse(self.set_fields)
      self.fields.each do |f|
        if data.has_key?(f.field_name)
          f.value = data[f.field_name]
          f.save!
        end
      end
    end
  end

  def mandatory_fields_are_set
    if !self.set_fields.blank? && self.annotation_type != 'dynamic'
      annotation_type = DynamicAnnotation::AnnotationType.where(annotation_type: self.annotation_type).last
      fields_set = JSON.parse(self.set_fields).keys
      mandatory_fields = annotation_type.schema.reject{ |instance| instance.optional }.map(&:name)
      errors.add(:base, 'Please set all mandatory fields') unless (mandatory_fields - fields_set).empty?
    end
  end

  def set_annotator
    self.annotator = User.current if !User.current.nil? && (self.annotator.nil? || self.annotation_type_object.singleton)
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
      team_id = self.annotated.project.team_id
      members_ids = TeamUser.where(team_id: team_id, status: 'member').map(&:user_id).map(&:to_i)
      invalid = []
      self.set_attribution.split(',').each do |uid|
        invalid << uid if !members_ids.include?(uid.to_i) && User.where(id: uid.to_i, is_admin: true).last.nil?
      end
      errors.add(:base, I18n.t(:error_invalid_attribution)) unless invalid.empty?
    end
  end
end
