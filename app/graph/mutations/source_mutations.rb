module SourceMutations
  MUTATION_TARGET = 'source'.freeze
  PARENTS = ['project_media'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :avatar, GraphQL::Types::String, required: false
      argument :user_id, GraphQL::Types::Int, required: false, camelize: false
      argument :add_to_project_media_id, GraphQL::Types::Int, required: false, camelize: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :slogan, GraphQL::Types::String, required: true
    argument :name, GraphQL::Types::String, required: true
    argument :urls, GraphQL::Types::String, required: false
    argument :validate_primary_link_exist, GraphQL::Types::Boolean, required: false, camelize: false
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :slogan, GraphQL::Types::String, required: false
    argument :name, GraphQL::Types::String, required: false
    argument :refresh_accounts, GraphQL::Types::Int, required: false, camelize: false
    argument :lock_version, GraphQL::Types::Int, required: false, camelize: false
  end
end
