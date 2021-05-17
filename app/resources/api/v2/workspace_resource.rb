module Api
  module V2
    class WorkspaceResource < BaseResource
      model_name 'Team'
      attributes :name, :slug
      paginator :none

      def self.records(options = {})
        self.workspaces(options)
      end

      filter :is_tipline_installed, apply: ->(records, value, _options) {
        bot = BotUser.smooch_user
        return records if bot.nil?
        if value && value[0]
          records.joins("INNER JOIN team_users tu2 ON tu2.team_id = teams.id AND tu2.user_id = #{bot.id}")
        else
          records.joins("LEFT OUTER JOIN team_users tu2 ON tu2.team_id = teams.id AND tu2.user_id = #{bot.id}").where('tu2.team_id' => nil)
        end
      }
    end
  end
end
