class BaseObject < GraphQL::Schema::Object
  field_class SnakeCaseField

  class << self
    def inherited(subclass)
      # This makes sure that the type arg passed to .id_from_object is our subclass,
      # not DefaultObject, which is intended to be abstract
      subclass.global_id_field :id
    end
  end
end
