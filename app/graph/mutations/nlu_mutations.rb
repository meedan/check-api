module NluMutations
  class ToggleKeywordInTiplineMenu < Mutations::BaseMutation
    argument :language, GraphQL::Types::String, required: true
    argument :keyword, GraphQL::Types::String, required: true
    argument :menu, GraphQL::Types::String, required: true # "main" or "secondary"
    argument :menu_option_index, GraphQL::Types::Int, required: true # zero-based... the order is the same displayed in the tipline and in the tipline settings page

    field :success, GraphQL::Types::Boolean, null: true

    def resolve(language:, menu:, menu_option_index:, keyword:)
      begin
        if User.current.is_admin
          nlu = SmoochNlu.new(Team.current.slug)
          nlu.enable!
          if toggle == :add
            nlu.add_keyword_to_menu_option(language, menu, menu_option_index, keyword)
          elsif toggle == :remove
            nlu.remove_keyword_from_menu_option(language, menu, menu_option_index, keyword)
          end
          { success: true }
        else
          { success: false }
        end
      rescue
        { success: false }
      end
    end
  end

  class AddKeywordToTiplineMenu < ToggleKeywordInTiplineMenu
    def toggle
      :add
    end
  end

  class RemoveKeywordFromTiplineMenu < ToggleKeywordInTiplineMenu
    def toggle
      :remove
    end
  end
end
