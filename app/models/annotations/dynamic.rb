class Dynamic < ActiveRecord::Base
  include AnnotationBase
  include NotifyEmbedSystem

  attr_accessor :set_fields, :set_attribution

  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  has_many :fields, class_name: 'DynamicAnnotation::Field', foreign_key: 'annotation_id', primary_key: 'id', dependent: :destroy

  before_validation :update_attribution
  after_save :add_update_elasticsearch_dynamic_annotation
  after_create :create_fields, :send_slack_notification
  after_update :update_fields, :send_slack_notification
  before_destroy :destroy_elasticsearch_dynamic_annotation

  validate :annotation_type_exists
  validate :mandatory_fields_are_set, on: :create
  validate :attribution_contains_only_team_members

  def slack_notification_message
    if !self.set_fields.blank? && self.annotation_type =~ /^task_response/
      self.slack_answer_task_message

    elsif !self.set_fields.blank? && self.annotation_type == 'translation_status'
      from, to = Bot::Slack.to_slack(self.previous_translation_status), Bot::Slack.to_slack(self.translation_status)

      if from != to
        I18n.t(:slack_update_translation_status,
          user: Bot::Slack.to_slack(User.current.name),
          report: Bot::Slack.to_slack_url("#{self.annotated_client_url}", "#{self.annotated.title}"),
          from: from,
          to: to
        )
      end
    end
  end

  def slack_answer_task_message
    response, note, task = self.values(['response', 'note', 'task'], '').values_at('response', 'note', 'task')
    task = Task.find(task).label

    note = I18n.t(:slack_answer_task_note, {note: Bot::Slack.to_slack_quote(note)}) unless note.blank?
    I18n.t(:slack_answer_task,
      user: Bot::Slack.to_slack(User.current.name),
      url: Bot::Slack.to_slack_url("#{self.annotated_client_url}", "#{task}"),
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

  def notify_destroyed?
    self.annotation_type == 'translation' && self.annotated_type == 'ProjectMedia'
  end
  alias notify_created? notify_destroyed?
  alias notify_updated? notify_destroyed?

  def notify_embed_system_created_object
    { id: self.annotated_id.to_s }
  end
  alias notify_embed_system_updated_object notify_embed_system_created_object

  def notify_embed_system_payload(event, object)
    { translation: object, condition: event, timestamp: Time.now.to_i }.to_json
  end

  def notification_uri(_event)
    project = self.annotated.project
    url = project.nil? ? '' : [CONFIG['bridge_reader_url_private'], 'medias', 'notify', project.team.slug, project.id, self.annotated.id.to_s].join('/')
    URI.parse(URI.encode(url))
  end

  private

  def add_update_elasticsearch_dynamic_annotation
    return if self.disable_es_callbacks
    method = "add_update_elasticsearch_dynamic_annotation_#{self.annotation_type}"
    if self.respond_to?(method)
      self.send(method)
    elsif self.fields.count > 0
      add_update_media_search_child('dynamic_search', ['indexable'])
    end
  end

  def destroy_elasticsearch_dynamic_annotation
    destroy_elasticsearch_data(DynamicSearch)
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
