class BaseConnection < GraphQL::Types::Relay::BaseConnection
  field :totalCount, GraphQL::Types::Int, null: true
end
