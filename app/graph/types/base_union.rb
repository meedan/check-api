class BaseUnion < GraphQL::Schema::Union
  connection_type_class ::BaseConnection
end
