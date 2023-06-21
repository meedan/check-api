module SourceMutations
  MUTATION_TARGET = 'source'.freeze
  PARENTS = ['project_media'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :avatar, String, required: false
      argument :user_id, Integer, required: false, camelize: false
      argument :add_to_project_media_id, Integer, required: false, camelize: false
    end
  end

  class Create < Mutations::CreateMutation
    include SharedCreateAndUpdateFields

    argument :slogan, String, required: true
    argument :name, String, required: true
    argument :urls, String, required: false
    argument :validate_primary_link_exist, Boolean, required: false
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :slogan, String, required: false
    argument :name, String, required: false
    argument :refresh_accounts, Integer, required: false, camelize: false
    argument :lock_version, Integer, required: false, camelize: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
