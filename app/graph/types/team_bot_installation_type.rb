module Types
  class TeamBotInstallationType < DefaultObject
    description "Team Bot Installation type"

    implements GraphQL::Types::Relay::NodeField

    field :json_settings, String, null: true

    field :lock_version, Integer, null: true

    def lock_version
      object.reload.lock_version
    end

    field :bot_user, BotUserType, null: true

    def bot_user
      RecordLoader.for(BotUser).load(object.user_id)
    end

    field :team, TeamType, null: true

    def team
      RecordLoader.for(Team).load(object.team_id)
    end

    field :alegre_settings, Types::JsonString, null: true

    # Only for Smooch Bot

    field :smooch_enabled_integrations, Types::JsonString, null: true do
      argument :force, Boolean, required: false
    end

    def smooch_enabled_integrations(**args)
      object.smooch_enabled_integrations(args[:force])
    end

    field :smooch_bot_preview_rss_feed, String, null: true do
      argument :rss_feed_url, String, required: true
      argument :number_of_articles, Integer, required: true
    end

    def smooch_bot_preview_rss_feed(**args)
      return nil unless object.bot_user.login == "smooch"
      ability = context[:ability] || Ability.new
      if ability.can?(:preview_rss_feed, Team.current)
        Bot::Smooch.render_articles_from_rss_feed(
          args[:rss_feed_url],
          args[:number_of_articles]
        )
      else
        I18n.t(:cant_preview_rss_feed)
      end
    end
  end
end
