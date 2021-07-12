class DynamicAnnotation::Field < ActiveRecord::Base
  include CheckElasticSearch
  include Versioned

  attr_accessor :disable_es_callbacks

  belongs_to :annotation
  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  belongs_to :field_instance, class_name: 'DynamicAnnotation::FieldInstance', foreign_key: 'field_name', primary_key: 'name'
  belongs_to :field_type_object, class_name: 'DynamicAnnotation::FieldType', foreign_key: 'field_type', primary_key: 'field_type'

  serialize :value, JSON

  before_validation :set_annotation_type, :set_field_type, :set_json_value

  validate :field_format

  after_commit :add_update_elasticsearch_field, on: [:create, :update]

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
    self.value.to_s
  end

  def as_json(options = {})
    json = super(options)
    json.merge({ formatted_value: self.to_s })
  end

  def team
    self.annotation.team
  end

  protected

  def method_suggestions(prefix)
    [
      "field_#{prefix}_#{self.annotation.annotation_type}_#{self.field_name}",
      "field_#{prefix}_name_#{self.field_name}",
      "field_#{prefix}_type_#{self.field_instance.field_type}",
    ]
  end

  private

  def add_update_elasticsearch_field
    # Handle analysis fields (title/ description)
    if self.annotation_type == "verification_status" && ['title', 'content'].include?(self.field_name)
      obj = self.annotation.project_media
      key = 'analysis_' + self.field_name.gsub('content', 'description')
      keys =  [key]
      data = { key => self.value }
      if self.field_name == 'title'
        keys << 'sort_title'
        data['sort_title'] = self.value.blank? ? obj.title&.downcase : self.value.downcase
      end
      self.update_elasticsearch_doc(keys, data, obj)
    end
  end

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
    self.value_json = self.value if self.field_type =~ /json/i && self.respond_to?(:value_json)
  end
end
