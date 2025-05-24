module UserMutations
  MUTATION_TARGET = 'user'.freeze
  PARENTS = ['me'].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :profile_image, GraphQL::Types::String, required: false, camelize: false
      argument :current_team_id, GraphQL::Types::Int, required: false, camelize: false
    end
  end

  class Update < Mutations::UpdateMutation
    include SharedCreateAndUpdateFields

    argument :email, GraphQL::Types::String, required: false
    argument :name, GraphQL::Types::String, required: false
    argument :password, GraphQL::Types::String, required: false
    argument :password_confirmation, GraphQL::Types::String, required: false, camelize: false

    argument :send_email_notifications, GraphQL::Types::Boolean, required: false, camelize: false
    argument :send_successful_login_notifications, GraphQL::Types::Boolean, required: false, camelize: false
    argument :send_failed_login_notifications, GraphQL::Types::Boolean, required: false, camelize: false
    argument :accept_terms, GraphQL::Types::Boolean, required: false, camelize: false
    argument :completed_signup, GraphQL::Types::Boolean, required: false, camelize: false
  end
end
