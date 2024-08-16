module ExportMutations
  class ExportList < Mutations::BaseMutation
    argument :query, GraphQL::Types::String, required: true

    field :success, GraphQL::Types::Boolean, null: true

    def resolve(query:)
      { success: false }
    end
  end
end
