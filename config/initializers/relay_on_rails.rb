# In order to implement mutations... create a file at `app/graph/types/mutation_type.rb` with the three lines below:
# MutationType = GraphQL::ObjectType.define do
#   name 'Mutation'
# end
# And then here:
# RelayOnRailsSchema = GraphQL::Schema.new(query: QueryType, mutation: MutationType)
RelayOnRailsSchema = GraphQL::Schema.new(query: QueryType)
