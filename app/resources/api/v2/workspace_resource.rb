module Api
  module V2
    class WorkspaceResource < BaseResource
      model_name 'Team'
      attributes :name, :slug
      paginator :none

      filter :is_tipline_installed, apply: ->(records, value, _options) {
        self.has_bot_installed(records, value, BotUser.smooch_user)
      }

      filter :is_similarity_feature_enabled, apply: ->(records, value, _options) {
        self.has_bot_installed(records, value, BotUser.alegre_user)
      }

      def self.records(options = {})
        self.workspaces(options)
      end

      def self.has_bot_installed(records, value, bot = nil)
        return records if bot.nil?
        is_false = !value || value[0].to_s == 'false' || value[0].to_s == '0'
        if is_false
          records.joins("LEFT OUTER JOIN team_users tu2 ON tu2.team_id = teams.id AND tu2.user_id = #{bot.id}").where('tu2.team_id' => nil)
        else
          records.joins("INNER JOIN team_users tu2 ON tu2.team_id = teams.id AND tu2.user_id = #{bot.id}")
        end
      end
    end
  end
end
