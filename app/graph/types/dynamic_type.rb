class DynamicType < AnnotationObject
  def type
    'dynamic'.freeze
  end

  field :lock_version, Integer, null: true
  field :sent_count, Integer, null: true # For "report_design" annotations
end
