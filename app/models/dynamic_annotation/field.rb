class DynamicAnnotation::Field < ActiveRecord::Base
  belongs_to :annotation
  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  belongs_to :field_instance, class_name: 'DynamicAnnotation::FieldInstance', foreign_key: 'field_name', primary_key: 'name'
  belongs_to :field_type_object, class_name: 'DynamicAnnotation::FieldType', foreign_key: 'field_type', primary_key: 'field_type'

  serialize :value

  before_validation :set_annotation_type, :set_field_type, :set_json_value

  validate :field_format

  # pairs = { key => value, ... }
  def self.find_in_json(pairs)
    conditions = {}
    pairs.each do |key, value|
      conditions[key] = value
    end
    DynamicAnnotation::Field.where('value_json @> ?', conditions.to_json)
  end

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

  def set_json_value
    self.value_json = self.value if self.field_type == 'json' && self.respond_to?(:value_json)
  end
end
