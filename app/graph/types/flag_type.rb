class FlagType < AnnotationObject
  def type
    'flag'.freeze
  end

  field :flag, String, null: true
end
