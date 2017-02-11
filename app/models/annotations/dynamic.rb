class Dynamic < ActiveRecord::Base
  include AnnotationBase

  attr_accessible

  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  has_many :fields, class_name: 'DynamicAnnotation::Field', foreign_key: 'annotation_id', primary_key: 'id'
  
  after_save :add_update_elasticsearch_dynamic_annotation

  def data
    fields = self.fields
    {
      'fields' => fields,
      'indexable' => fields.map(&:value).select{ |v| v.is_a?(String) }.join('. ')
    }
  end

  private

  def add_update_elasticsearch_dynamic_annotation
    add_update_media_search_child('dynamic_search', ['indexable']) if self.fields.count > 0
  end
end
