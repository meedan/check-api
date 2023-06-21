module TagTextMutations
  MUTATION_TARGET = 'tag_text'.freeze
  PARENTS = ['team'].freeze

  class Create < Mutations::CreateMutation
    argument :team_id, Integer, required: true, camelize: false
    argument :text, String, required: true
  end

  class Update < Mutations::UpdateMutation
    argument :text, String, required: false
  end

  class Destroy < Mutations::DestroyMutation; end
end
