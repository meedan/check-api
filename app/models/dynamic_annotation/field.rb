class DynamicAnnotation::Field < ApplicationRecord
  include CheckElasticSearch
  has_paper_trail on: [:create, :update], save_changes: true, ignore: [:updated_at, :created_at], if: proc { |f| User.current.present? && (['verification_status_status', 'team_bot_response_formatted_data', 'language'].include?(f.field_name) || f.annotation_type == 'archiver' || f.annotation_type =~ /^task_response/) }, versions: { class_name: 'Version' }

  attr_accessor :disable_es_callbacks, :bypass_status_publish_check

  belongs_to :annotation, optional: true
  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type', optional: true
  belongs_to :field_instance, class_name: 'DynamicAnnotation::FieldInstance', foreign_key: 'field_name', primary_key: 'name', optional: true
  belongs_to :field_type_object, class_name: 'DynamicAnnotation::FieldType', foreign_key: 'field_type', primary_key: 'field_type', optional: true

  serialize :value, JSON

  before_validation :set_annotation_type, :set_field_type, :set_json_value

  validate :field_format

  after_commit :add_elasticsearch_field, on: :create
  after_commit :update_elasticsearch_field, on: :update
  after_commit :destroy_elasticsearch_field, on: :destroy

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
    self.annotation&.team
  end

  def associated_graphql_id
    annotation = self.annotation
    Base64.encode64("#{annotation.annotated_type}/#{annotation.annotated_id}")
  end

  private

  def add_elasticsearch_field
    index_field_elastic_search('create')
  end

  def update_elasticsearch_field
    index_field_elastic_search('update')
  end

  def destroy_elasticsearch_field
    index_field_elastic_search('destroy')
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
    if self.field_type =~ /json/i && self.respond_to?(:value_json)
      begin
        self.value_json = JSON.parse(self.value.to_s)
      rescue JSON::ParserError
        self.value_json = self.value
      end
    end
  end

  protected

  def method_suggestions(prefix)
    [
      "field_#{prefix}_#{self.annotation&.annotation_type}_#{self.field_name}",
      "field_#{prefix}_name_#{self.field_name}",
      "field_#{prefix}_type_#{self.field_instance&.field_type}",
    ]
  end

  def index_field_elastic_search(op)
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    obj = self.annotation&.project_media
    apply_field_index(obj, op) unless obj.nil?
  end

  def apply_field_index(obj, op)
    data = {}
    # Handle analysis fields (title/ description)
    if self.annotation_type == "verification_status" && ['file_title', 'title', 'content'].include?(self.field_name)
      key = 'analysis_' + self.field_name.gsub('content', 'description')
      key = 'analysis_title' if self.field_name == 'file_title'
      data = op == 'destroy' ? { key => '' } : { key => self.value }
    elsif self.annotation_type == "language"
      # Handle language field
      data = op == 'destroy' ? { 'language' => '' } : { 'language' => self.value }
    end
    obj.update_elasticsearch_doc(data.keys, data, obj.id, true) unless data.blank?
  end
end
