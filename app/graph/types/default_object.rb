class DefaultObject < BaseObject
  class << self
    def inherited(subclass)
      # This makes sure that the type arg passed to .id_from_object is our subclass,
      # not DefaultObject, which is intended to be abstract
      subclass.global_id_field :id
    end
  end
  
  field :permissions, GraphQL::Types::String, null: true

  def permissions
    object.permissions(context[:ability])
  end

  field :created_at, GraphQL::Types::String, null: true

  def created_at
    object.created_at.to_i.to_s if object.respond_to?(:created_at)
  end

  field :updated_at, GraphQL::Types::String, null: true

  def updated_at
    object.updated_at.to_i.to_s if object.respond_to?(:updated_at)
  end
end
