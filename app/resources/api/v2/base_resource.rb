module Api
  module V2
    class BaseResource < JSONAPI::Resource
      # Data should be always scoped by workspace
      def self.workspaces(options = {})
        user = options.dig(:context, :current_user)
        teams = Team.none
        if user
          teams = user.teams
        elsif options.dig(:context, :current_api_key) && !User.current&.id
          teams = Team.all
        end
        teams
      end
    end
  end
end
