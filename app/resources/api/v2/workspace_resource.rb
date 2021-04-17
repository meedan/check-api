module Api
  module V2
    class WorkspaceResource < BaseResource
      model_name 'Team'
      attributes :name, :slug
      paginator :none

      def self.records(options = {})
        self.workspaces(options)
      end
    end
  end
end
