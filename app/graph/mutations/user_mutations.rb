module UserMutations
  MUTATION_TARGET = 'user'.freeze
  PARENTS = [].freeze

  module SharedCreateAndUpdateFields
    extend ActiveSupport::Concern

    included do
      argument :profile_image, String, required: false, camelize: false
      argument :current_team_id, Integer, required: false, camelize: false
    end
  end

  class Create < Mutation::Create
    include SharedCreateAndUpdateFields

    argument :email, String, required: true
    argument :login, String, required: true
    argument :name, String, required: true
    argument :password, String, required: true
    argument :password_confirmation, String, required: true
  end

  class Update < Mutation::Update
    include SharedCreateAndUpdateFields

    argument :email, String, required: false
    argument :name, String, required: false
    argument :current_project_id, Integer, required: false, camelize: false
    argument :password, String, required: false
    argument :password_confirmation, String, required: false, camelize: false

    argument :send_email_notifications, Boolean, required: false, camelize: false
    argument :send_successful_login_notifications, Boolean, required: false, camelize: false
    argument :send_failed_login_notifications, Boolean, required: false, camelize: false
    argument :accept_terms, Boolean, required: false, camelize: false
    argument :completed_signup, Boolean, required: false, camelize: false
  end

  class Destroy < Mutation::Destroy; end
end
