class BaseObject < GraphQL::Schema::Object
  connection_type_class ::BaseConnection

  field_class SnakeCaseField
end
