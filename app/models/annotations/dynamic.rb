class Dynamic < ActiveRecord::Base
  include AnnotationBase

  attr_accessor :set_fields

  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  has_many :fields, class_name: 'DynamicAnnotation::Field', foreign_key: 'annotation_id', primary_key: 'id', dependent: :destroy

  after_save :add_update_elasticsearch_dynamic_annotation
  after_create :create_fields
  after_update :update_fields
  before_destroy :destroy_elasticsearch_dynamic_annotation

  validate :annotation_type_exists
  validate :mandatory_fields_are_set, on: :create

  annotation_notifies_slack :update
  annotation_notifies_slack :create

  def slack_message
    if !self.set_fields.blank? && self.annotation_type =~ /^task_response/
      response, note, task = self.values(['response', 'note', 'task'], '-').values_at('response', 'note', 'task')
      task = Task.find(task).label

      I18n.t(:slack_answer_task,
        user: self.class.to_slack(User.current.name),
        url: self.class.to_slack_url("#{self.annotated_client_url}", "#{task}"),
        project: self.class.to_slack(self.annotated.project.title),
        response: self.class.to_slack_quote(response),
        note: self.class.to_slack_quote(note)
      )
    end
  end

  def data
    fields = self.fields
    {
      'fields' => fields,
      'indexable' => fields.map(&:value).select{ |v| v.is_a?(String) }.join('. ')
    }
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

  private

  def add_update_elasticsearch_dynamic_annotation
    add_update_media_search_child('dynamic_search', ['indexable']) if self.fields.count > 0
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
        f = DynamicAnnotation::Field.new
        f.skip_check_ability = true
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
    self.annotator = User.current if !User.current.nil?
  end
end
