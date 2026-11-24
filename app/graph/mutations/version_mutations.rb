module VersionMutations
  MUTATION_TARGET = 'version'.freeze
  PARENTS = ['project_media', 'source'].freeze

  class Destroy < Mutations::DestroyMutation
    def resolve(**inputs)
      type, id = CheckGraphql.decode_id(inputs[:id].to_s)
      team = Team.current
      raise ActiveRecord::RecordNotFound if type != 'Version' || team.nil?
      version = Version.from_partition(team.id).where(id: id, team_id: team.id).last
      raise ActiveRecord::RecordNotFound if version.nil?
      ability = context[:ability] || Ability.new
      raise CheckPermissions::AccessDenied, I18n.t(:permission_error) unless ability.can?(:destroy, version)
      GraphqlCrudOperations.destroy_from_single_id(inputs[:id], version, inputs, context, PARENTS)
    end
  end
end
