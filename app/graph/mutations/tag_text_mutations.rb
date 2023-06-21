module TagTextMutations
  MUTATION_TARGET = 'tag_text'.freeze
  PARENTS = ['team'].freeze

  class Create < Mutation::Create
    argument :team_id, Integer, required: true, camelize: false
    argument :text, String, required: true
  end

  class Update < Mutation::Update
    argument :text, String, required: false
  end

  class Destroy < Mutation::Destroy; end
end
