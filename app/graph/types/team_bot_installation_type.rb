class TeamBotInstallationType < DefaultObject
  description "Team Bot Installation type"

  implements GraphQL::Types::Relay::Node

  field :json_settings, GraphQL::Types::String, null: true

  field :lock_version, GraphQL::Types::Int, null: true

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

  field :alegre_settings, JsonStringType, null: true

  # Only for Smooch Bot

  field :smooch_enabled_integrations, JsonStringType, null: true do
    argument :force, GraphQL::Types::Boolean, required: false
  end

  def smooch_enabled_integrations(force: nil)
    object.smooch_enabled_integrations(force)
  end

  field :smooch_bot_preview_rss_feed, GraphQL::Types::String, null: true do
    argument :rss_feed_url, GraphQL::Types::String, required: true, camelize: false
    argument :number_of_articles, GraphQL::Types::Int, required: true, camelize: false
  end

  def smooch_bot_preview_rss_feed(rss_feed_url:, number_of_articles:)
    return nil unless object.bot_user.login == "smooch"
    ability = context[:ability] || Ability.new
    team = Team.current
    if ability.can?(:preview_rss_feed, team)
      rss_feed = RssFeed.new(rss_feed_url)
      content = rss_feed.get_articles(number_of_articles).join("\n\n")
      team.get_shorten_outgoing_urls ? UrlRewriter.shorten_and_utmize_urls(content, team.get_outgoing_urls_utm_code) : content
    else
      I18n.t(:cant_preview_rss_feed)
    end
  end

  field :smooch_default_messages, JsonStringType, null: true

  def smooch_default_messages
    object.smooch_default_messages
  end
end
