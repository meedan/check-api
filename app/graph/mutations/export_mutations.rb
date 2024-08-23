module ExportMutations
  class ExportList < Mutations::BaseMutation
    argument :query, GraphQL::Types::String, required: true # JSON
    argument :type, GraphQL::Types::String, required: true # 'media', 'feed', 'fact-check' or 'explainer'

    field :success, GraphQL::Types::Boolean, null: true

    def resolve(query:, type:)
      ability = context[:ability]
      team = Team.find_if_can(Team.current.id, ability)
      if ability.cannot?(:export_list, team)
        { success: false }
      else
        export = ListExport.new(type.to_sym, query, team.id)
        if export.number_of_rows > CheckConfig.get(:export_csv_maximum_number_of_results, 10000, :integer)
          { success: false }
        else
          export.generate_csv_and_send_email_in_background(User.current)
          { success: true }
        end
      end
    end
  end
end
