class DefaultObject < BaseObject
  global_id_field :id

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
