module CheckDataExportMutations
  MUTATION_TARGET = 'check_data_export'.freeze
  PARENTS = [].freeze

  class Create < Mutations::CreateMutation
    argument :status, GraphQL::Types::String, required: false
  end
end
