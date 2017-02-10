class Dynamic < ActiveRecord::Base
  include AnnotationBase

  attr_accessible

  belongs_to :annotation_type_object, class_name: 'DynamicAnnotation::AnnotationType', foreign_key: 'annotation_type', primary_key: 'annotation_type'
  has_many :fields, class_name: 'DynamicAnnotation::Field', foreign_key: 'annotation_id', primary_key: 'id'
end
