class DynamicAnnotation::Field < ActiveRecord::Base
  include NotifyEmbedSystem

  belongs_to :annotation
  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  belongs_to :field_instance, class_name: 'DynamicAnnotation::FieldInstance', foreign_key: 'field_name', primary_key: 'name'
  belongs_to :field_type_object, class_name: 'DynamicAnnotation::FieldType', foreign_key: 'field_type', primary_key: 'field_type'

  serialize :value

  before_validation :set_annotation_type, :set_field_type

  validate :field_format

  def to_s
    self.method_suggestions('formatter').each do |name|
      return self.send(name) if self.respond_to?(name)
    end
    self.value
  end

  def as_json(options = {})
    json = super(options)
    json.merge({ formatted_value: self.to_s })
  end

  def notify_destroyed?
    self.field_name == 'translation_text'
  end
  alias notify_created? notify_destroyed?
  alias notify_updated? notify_destroyed?

  def notify_embed_system_created_object
    { id: self.annotation.annotated_id.to_s }
  end
  alias notify_embed_system_updated_object notify_embed_system_created_object

  def notify_embed_system_payload(event, object)
    { translation: object, condition: event, timestamp: Time.now.to_i }.to_json
  end

  def notification_uri(_event)
    annotated = self.annotation.annotated
    project = annotated.project
    url = project.nil? ? '' : [CONFIG['bridge_reader_url_private'], 'medias', 'notify', project.team.slug, project.id, annotated.id.to_s].join('/')
    URI.parse(URI.encode(url))
  end

  include Versioned

  protected

  def method_suggestions(prefix)
    [
      "field_#{prefix}_#{self.annotation.annotation_type}_#{self.field_name}",
      "field_#{prefix}_name_#{self.field_name}",
      "field_#{prefix}_type_#{self.field_instance.field_type}",
    ]
  end

  private

  def field_format
    self.method_suggestions('validator').each do |name|
      self.send(name) if self.respond_to?(name)
    end
  end

  def set_annotation_type
    self.annotation_type ||= self.annotation.annotation_type
  end

  def set_field_type
    self.field_type ||= self.field_instance.field_type
  end
end
