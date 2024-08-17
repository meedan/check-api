module ExportMutations
  class ExportList < Mutations::BaseMutation
    argument :query, GraphQL::Types::String, required: true

    field :success, GraphQL::Types::Boolean, null: true

    def resolve(query:)
      ability = context[:ability]
      team = Team.find_if_can(Team.current.id, ability)
      if ability.cannot?(:export_list, team)
        { success: false }
      else
        search = CheckSearch.new(query, nil, team.id)
        if search.number_of_results > CheckConfig.get(:export_csv_maximum_number_of_results, 10000, :integer)
          { success: false }
        else
          CheckSearch.delay.export_to_csv(query, team.id)
          { success: true }
        end
      end
    end
  end
end
